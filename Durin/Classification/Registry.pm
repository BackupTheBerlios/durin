package Durin::Classification::Registry;

use strict;

my $registry = {};

sub register
  {
    my ($class,$name,$module) = @_;
    
    $registry->{$name} = $module;
  }

sub getInducer
  {
    my ($class,$name) = @_;
    
    my ($module,$inducer);
    
    if (!exists $registry->{$name})
      {
	die "Inducer $inducer not registered\n";
      }
    $module = $registry->{$name};
    $inducer = new $module;
    return $inducer;
  }

1;
