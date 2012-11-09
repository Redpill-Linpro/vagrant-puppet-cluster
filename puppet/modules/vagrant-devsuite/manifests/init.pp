# == Class: vagrant-devsuite
#
# === Authors
#
# Harald Skoglund <haraldsk@redpill-linpro.com>
#
# === Copyright
#
# Copyright 2012 Redpill Linpro AS
#
class vagrant-devsuite inherits vagrant-devsuite::params {

  class{ "vagrant-devsuite::${osfamily}":  }

  include vagrant-devsuite::configure
  include vagrant-devsuite::configure::hostconf
}

class vagrant-devsuite::configure {


  $puppet_conf = '/etc/puppet/puppet.conf'
  ini_setting { 
    "puppet_pluginsync":
      ensure => present,
      path    => $puppet_conf,
      section => 'main',
      setting => 'pluginsync',
      value   => 'true';
    "puppet_listen":
      ensure => present,
      path    => $puppet_conf,
      section => 'agent',
      setting => 'listen',
      value   => 'false',
  }

}


# Gets /etc/hosts from host.yaml in vagrant root
class vagrant-devsuite::configure::hostconf {

  $h = regsubst($clientcert, '^(.*?)\..*', '\1')
  file {
    '/etc/hostname':
      ensure  => present, 
      content => "${h}\n";
  }
}
