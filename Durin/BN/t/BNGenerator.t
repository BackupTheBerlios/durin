#!/usr/bin/perl

use strict;
use warnings;

#use Durin::Metadata::ATCreator;
#use Durin::TAN::RandomTANGenerator;
#use Durin::ModelGeneration::ModelGenerator;
use Durin::BN::BNGenerator;
use Durin::BN::BN;

my $BNGen = Durin::BN::BNGenerator->new;
my $BN = $BNGen->generateModel();
print $BN->toString()."\n";
for (my $i = 1 ; $i< 10; $i++) {
  my $row = $BN->generateObservation();
  print join(",",@$row)."\n";
}

#End
