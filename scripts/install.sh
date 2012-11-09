#! /bin/bash
#
# Shell script to automatically install puppet on a fresh host
#
# $Id: install.erb 68202 2012-10-04 11:21:34Z kjetilho $
#

PATH="$PATH:/sbin:/usr/sbin:/bin:/usr/bin"

# Function to supply data where needed. Uses lsb_release if present, queries
# user if not.
lsb_get () {

    case "$1" in
        "id")
            ID="unknown"
            if $HAS_LSB; then
                ID=$(lsb_release -si)
            else
                default="Debian"
                if [ -f /etc/redhat-release ]; then
                    default="RedHatEnterpriseES"
                fi
                echo -n "Please enter distribution (Debian, Ubuntu, RedHatEnterpriseES) [$default]: "
                read ID
                if [ "x$ID" = "x" ]; then
                    ID=$default
                fi
            fi
            ;;
        "release")
            RELEASE="unknown"
            if $HAS_LSB ; then
                # The release number, not the codename, since CentOS uses
                # different names than Red Hat (e.g., "Final"), and numbers are
                # more convenient anyway.
                RELEASE=$(lsb_release -sr)
            else
                default="unknown"
                case "$ID" in
                    Debian)
                        default="4.0"
                        ;;
                    Ubuntu)
                        default="6.06"
                        ;;
                    RedHatEnterpriseES)
                        if rpm -q redhat-release >/dev/null; then
                            default=$(rpm -q --qf '%{version}.%{release}\n' redhat-release)
                        elif rpm -q centos-release >/dev/null; then
                            default=$(rpm -q --qf '%{version}.%{release}\n' centos-release | cut -d. -f-2)
                        elif rpm -q sl-release >/dev/null; then
                            default=$(rpm -q --qf '%{version}.%{release}\n' sl-release | cut -d. -f-2)
                        elif [ -f /etc/redhat-release ]; then
                            default=$(cut -f3 -d" " /etc/redhat-release)
                        else
                            default="4.0"
                        fi
                        ;;
                esac
                echo -n "Please enter distribution version (4.0, 5.2, ...) [$default]: "
                read RELEASE
                if [ -z "$RELEASE" ]; then
                    RELEASE="$default"
                fi
            fi
            ;;
    esac

}

install_lsb_release () {
    if ! type lsb_release >/dev/null 2>&1; then
        if type apt-get >/dev/null 2>&1; then
            apt-get --quiet=2 install lsb-release
        fi
        if type yum >/dev/null 2>&1; then
            yum -y install redhat-lsb
        fi
    fi
}


# Install puppet on a redhat box
install_puppet_redhat () {

    echo "* Installing facter and puppet..."
    case $RELEASE in
        6*)
          rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-6.noarch.rpm
          ;;
        5*)
          rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-6.noarch.rpm
        ;;
    esac

    yum clean all
    yum -y install puppet facter

}


# Install puppet on a debian box
install_puppet_debian () {

    apt_options="--quiet=2"

    case "$ID-$RELEASE" in
        Ubuntu-10.04*)
          wget -O /tmp/puppetlabs-release.deb http://apt.puppetlabs.com/puppetlabs-release-lucid.deb
            ;;
        Ubuntu-12.04*)
          wget -O /tmp/puppetlabs-release.deb http://apt.puppetlabs.com/puppetlabs-release-precise.deb
            ;;
    esac

    dpkg -i /tmp/puppetlabs-release.deb
    apt-get $apt_options update
    apt-get $apt_options install puppet facter

}

postinstall_puppetrun () {
    puppet apply -e '

    File {
      owner => puppet,
      group => root,
    }

    file {
        # Install puppet.conf
        "/etc/puppet/puppet.conf":
            ensure => present,
            source => "/vagrant/install/puppet.conf";
        # Remove old puppetd.conf
        "/etc/puppet/puppetd.conf":
            ensure => absent;
    }

    # Create directories to ensure puppet agent can run with --noop
    file {
        "/var/lib/puppet":
            ensure => directory;
        "/var/lib/puppet/client_yaml":
            ensure => directory;
        "/var/lib/puppet/client_yaml/catalog":
            ensure => directory;
    }
'
}

clean_vagrant_box () {

  echo "Removing vagrant ruby that always messes up stuff.."
  rm -rf /opt/vagrant_ruby
  echo "And puppet binaries.."
  rm -f /usr/local/bin/puppetd /usr/sbin/puppetd /usr/local/sbin/puppetd

}


setup_hosts() {
  cp /vagrant/install/hosts /etc/hosts
  chown root.root /etc/hosts

}

puppet_installed() {
  touch /.PUPPET-INSTALLED
}

run_puppet_agent() {
    echo
    echo "Trying a puppet agent run"
    puppet agent --test 2>&1 |
        tee /tmp/puppet.$$.run
    echo

    if grep "Finished catalog run" /tmp/puppet.$$.run >/dev/null
    then
        echo "Thank you for installing Puppet."
        echo "Everything is hunky-dory, even this node's certificate is signed"
        puppet_installed
    elif egrep 'please remove certificate from server' /tmp/puppet.$$.run >/dev/null
    then
    # We need to remove the certificate files from both node and server
    # to get a matching set
        rm -f /var/lib/puppet/ssl/*/*.pem
        echo "Log on to puppetmaster and run 'sudo puppet node --clean $hostname'"
        echo "Then run 'puppet agent -t' to request a new certificate"
        echo "Then on puppetmaster: 'sudo puppet cert --sign $hostname'"
    elif egrep "(Could not request|Did not receive|No) certificate|Creating a new SSL certificate request" /tmp/puppet.$$.run >/dev/null
    then
        echo "Thank you for installing Puppet."
        echo "Now log in to puppetmaster and run 'sudo puppet cert --sign $hostname'"
        echo "(If reinstalling, first run 'sudo puppet node --clean $hostname')"
    elif grep "puppet: command not found" /tmp/puppet.$$.run >/dev/null
    then
        echo "Oops, failed to find puppet." >&2
        echo "Please notify MS0 if this script could handle it better" >&2
        exit 1
    elif grep "no certificate found and waitforcert is disabled" /tmp/puppet.$$.run >/dev/null
    then
        sed 's/^ *//' >&2 <<EOF
        A certificate request has already been created.  If
        signing the certificate on puppetmaster doesn't work, you
        may want to "rm /var/lib/puppet/ssl/*/*.pem" and rerun
        "puppet agent --test --noop" to generate a new request.
EOF
    else
        echo "Oops, something failed." >&2
        echo "Please notify MS0." >&2
    fi
}

usage() {
    echo "$0 [--help|-h] [--skip-puppet-agent]"
    exit 1
}

##############################
# Real work starts here

# Defaults
run_puppet_agent=yes

# Parse command line arguments.
TEMP=$(getopt \
    --name $0 \
    --options h \
    --long skip-puppet-agent,help \
    -- "$@")

if [ $? != 0 ]; then
    usage
    exit 1
fi

eval set -- "$TEMP"
while :; do
    case $1 in
        --help|-h)
            usage
            exit 0
            ;;
        --skip-puppet-agent)
            run_puppet_agent=no; shift; continue
            ;;
        --)
            break
            ;;
        *)
            printf "Unknown option: %s\n" "$1"
            exit 1
            ;;
    esac
done

# Install needed packages
install_lsb_release
if type lsb_release >/dev/null 2>&1
then
    HAS_LSB=true
else
    HAS_LSB=false
    echo "Warning: Could not find \"lsb_release\" -- you will be prompted"
    echo "         for some information."
    echo
fi


lsb_get id
lsb_get release

case $(uname -n) in
    localhost*)
        echo "Please configure hostname first"
        exit 1
        ;;
    *puppet*)
        if [ -r /etc/puppet/puppet.conf ] &&
           fgrep '[puppetmasterd]' /etc/puppet/puppet.conf >/dev/null
        then
            echo "I don't think you should run this script here."
            echo "(To force installation, edit this script.)"
            exit 1
        fi
        ;;
esac

OS=$(uname)
ARCH=$(uname -i 2>/dev/null || uname -m)
if [ "$ARCH" = "unknown" ]; then ARCH=$(uname -m); fi
hostname=$(uname -n)

echo "OS            : $ARCH $OS"
echo "Distribution  : $ID $RELEASE"

case "$OS" in
    Linux)
      setup_hosts
      clean_vagrant_box
        case "$ID" in
            RedHatEnterprise*|CentOS|Scientific)
                install_puppet_redhat
                postinstall_puppetrun
                ;;
            Debian|Ubuntu)
                install_puppet_debian
                postinstall_puppetrun
                ;;
            *)
                echo "Unknown distribution \"$ID\"."
                exit 1
                ;;
        esac
        hostname=$(hostname --fqdn)
        ;;
    *)
        echo "Unknown operating system \"$OS\"."
        exit 1
        ;;
esac

case $run_puppet_agent in
    yes)
        run_puppet_agent
        ;;
    *)
        :
        ;;
esac
