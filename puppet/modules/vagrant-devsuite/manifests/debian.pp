class vagrant-devsuite::debian {

  File {
    owner  => 'root',
    group  => 'root',
  }

  case $::operatingsystem {
    'ubuntu': {
      apt::source { 'puppetlabs':
        location   => 'http://apt.puppetlabs.com',
        repos      => 'main',
        key        => '4BD6EC30',
        key_server => 'subkeys.pgp.net',
      }
      package { 
        'puppet':
          ensure  => latest,
          notify  => Exec['remove puppet vagrant'],
          require => [ Apt::Source['puppetlabs'], File['/usr/local/bin/puppetd']];
        [ 'libaugeas-ruby',  'augeas-tools', 'augeas-lenses' ]:
          ensure => latest,
      }
      case $::lsbdistcodename { 
        'precise': {
          package { 'libaugeas-ruby1.9.1':
            ensure => present,
          }
        } 
        'lucid': {
          # god damn puppet / augeas
          # http://projects.puppetlabs.com/issues/16203
          apt::source { 'lucid-backports':
            location => 'http://no.archive.ubuntu.com/ubuntu/',
            release  => 'lucid-backports',
            repos    => 'main restricted universe multiverse',
            before   => Package['libaugeas-ruby'],
          }
        }
      }
    }
  }


}
