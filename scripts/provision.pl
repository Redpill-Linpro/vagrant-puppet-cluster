#!/usr/bin/perl
use strict;
use warnings;

if ( -f "/.PUPPET-INSTALLED" ) {

  my $retval = system("puppet agent --test");

  if($retval == 0 or $retval == 2 or $retval == 512) {
    exit(0);
  } else {
    die($retval);
  }
} else {
  system('sh /vagrant/scripts/install.sh')
}
