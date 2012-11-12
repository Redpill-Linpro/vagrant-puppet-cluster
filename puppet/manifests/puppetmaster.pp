Package {
  require => [Exec["apt-get update"], Apt::Source['puppetlabs']]
}

class { puppetmaster:
  puppetmaster_package_ensure => 'latest',
  puppetmaster_server         => 'puppet.int.net',
  puppetmaster_certname       => 'puppet.int.net',
  puppetmaster_service_ensure => 'running',
  puppetmaster_service_enable => 'true',
  puppetmaster_report         => 'true',
  puppetmaster_autosign       => 'true',
  puppetmaster_modulepath     => '$confdir/site/modules:$confdir/modules:$confdir/modules-0',
  require                     => Apt::Source['puppetlabs'],
}

exec {
  'apt-get update':
    command     => '/usr/bin/apt-get update',
    refreshonly => true;
   # This will copy puppet files to your vagrant-dir on a fresh
   # install but not mess with it if you allready have a config
   # present
   'copy-puppetmaster-config':
    command     => '/bin/cp -R /etc/puppet/* /vagrant/puppet/',
    refreshonly => true,
    onlyif      => '/usr/bin/test ! -e /vagrant/puppet/puppet.conf',
    require     =>  Class['puppetmaster'];
}

apt::source { 'puppetlabs':
  location   => 'http://apt.puppetlabs.com',
  repos      => 'main',
  key        => '4BD6EC30',
  key_server => 'subkeys.pgp.net',
}


package {
  'puppetmaster-passenger':
    ensure  => absent;
  [ 'libaugeas-ruby', 'libaugeas-ruby1.9.1', 'augeas-tools', 'augeas-lenses' ]:
    ensure => installed,
    notify => Service['puppetmaster'];
  # Storedconfigs
  ['libactiverecord-ruby1.9.1', 'sqlite3', 'libsqlite3-ruby']:
    ensure => installed,
    notify => Service['puppetmaster'],
}



host {
  'puppet.int.net':
  ensure       => present,
  ip           => '10.0.0.10',
  host_aliases => [ 'puppet.int.net'],
  before       =>  Class['puppetmaster'],
}

file {
  # '/etc/hostname':
  #   ensure  => present,
  #   content => "puppet\n";
  '/etc/puppet':
    ensure => link,
    force  => true,
    target => '/vagrant/puppet',
    require => Exec['copy-puppetmaster-config'],
}
