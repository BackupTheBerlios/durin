#!/usr/bin/perl -w 

# This scripts summarizes the results of an already run experiment

if ($#ARGV < 0)
  {
    print "This script summarizes the results of an already run experiment";
    die "Usage: SummarizeExperiment.pl experiment.exp\n";
  }

my $inFilePos = 0;

$ExpFileName = $ARGV[$inFilePos];

our $exp;

my $exp_chr = do $ExpFileName;
my $exp = Durin::Classification::Experimentation::ExperimentFactory->createExperiment($exp_chr);
$exp->summarize();
