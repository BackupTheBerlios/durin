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
my $row = $BN->generateObservation();
print join(",",@$row)."\n";
#End
