#!/usr/bin/perl

if ( -e "/.PUPPET-INSTALLED" ) {
  
  $retval = system("puppet agent --test");
  
  if($retval == 0 or $retval == 2 or $retval == 512) {
  # This doesn't work on perl < 5.10
  # if($retval ~~ [0,2,512]) {
    exit(0);
  } else {
    die($retval);
  }
}
else {
  system('/vagrant/scripts/install.sh')
}
