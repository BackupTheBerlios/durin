#!/usr/bin/perl -w 

# This scripts runs an experiment

#use Durin::Metadata::ATCreator;
#use Durin::Classification::System;
use Durin::Classification::Experimentation::ExperimentFactory;

$| = 1;

if ($#ARGV < 0)
  {
    print "This script runs an experiment";
    die "Usage: RunExperiment.pl experiment.exp.pm </dev/null >& tracefile \n";
  }

my $inFilePos = 0;

$ExpFileName = $ARGV[$inFilePos];
$traceFile = $ARGV[$2];
my $exp_chr = do $ExpFileName;

my $exp = Durin::Classification::Experimentation::ExperimentFactory->createExperiment($exp_chr);
$exp->run();

