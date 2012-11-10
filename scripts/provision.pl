#!/usr/bin/perl
use strict;
use warnings;

if ( -f "/.PUPPET-INSTALLED" ) {

  # Specifying server here so no broken config can cock it up
  my $retval = system("puppet agent --test --server puppet.int.net");

  if($retval == 0 or $retval == 2 or $retval == 512) {
    exit(0);
  } else {
    die($retval);
  }
} else {
  system('sh /vagrant/scripts/install.sh')
}
