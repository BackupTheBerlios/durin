#!/usr/bin/perl -w 

# This scripts generates the comparison graphs for an experiment using gnuplot

use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::CompleteResultTable;
use Durin::ProbClassification::ProbModelApplication;
use Durin::Utilities::MathUtilities;
use Durin::Classification::Experimentation::ExperimentFactory;

use PDL::Graphics::PGPLOT;
use PDL;
use PGPLOT;
use PDL::Primitive;
use IO::File;
use File::Temp;
use Text::Template;
use Env;
use DBI;
#DBI->trace(1);
use strict;
use warnings;

if ($#ARGV < 0)
  {
    print "This script generates comparison graphs for the results of an experiment using gnuplot";
    die "Usage: gnuplotExperimentGraphs.pl experiment.exp \n";
  }

my $inFilePos = 0;
my $generatePostcriptPos = 1;
my $ER = 1;
my $LOGP = 2;

my $ExpFileName = $ARGV[$inFilePos];

#our $exp;

my $exp_chr = do $ExpFileName;
my $exp = Durin::Classification::Experimentation::ExperimentFactory->createExperiment($exp_chr);
#$exp->run(); 
my $AveragesTable = Durin::Classification::Experimentation::CompleteResultTable->new();
print "I am going to migrate\n";
$exp->dumpSummariesToSQLite();
