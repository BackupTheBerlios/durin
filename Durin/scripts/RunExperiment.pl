#!/usr/bin/perl -w 

# This scripts runs an experiment

#use Durin::Metadata::ATCreator;
#use Durin::Classification::System;

$| = 1;

if ($#ARGV < 0)
  {
    print "This script runs an experiment";
    die "Usage: RunExperiment.pl experiment.exp\n";
  }

my $inFilePos = 0;

$ExpFileName = $ARGV[$inFilePos];

our $exp;

do $ExpFileName;

$exp->run();

