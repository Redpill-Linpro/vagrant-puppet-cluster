class vagrant-devsuite::params (
) {

# Somehow the ::osfamliy fact doesnt exist on some old systems

case $::operatingsystem {
  'centos', 'redhat', 'scientific', 'fedora': {
    $osfamily = 'redhat'
  } 'debian', 'ubuntu': {
    $osfamily = 'debian'
  } 'windows': {
    fail('fail!11')
  } default: {
    fail("OS: ${::operatingsystem} not supported")
  }
}
}
