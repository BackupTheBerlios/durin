#!/usr/bin/perl -w 

use strict;
use warnings;

use IO::File;
use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::CompleteResultTable;
use Durin::ProbClassification::ProbModelApplication;
use Durin::Utilities::MathUtilities;
use Statistics::Distributions;

my $inFile = 0;

if ($#ARGV < 0)
  {
    print "Generates a file with the significance tests results for the different pair comparisons\n";
    die "Usage: SignificanceTest.pl experiment.exp [percentage]\n";
  }

my $ExpFileName = $ARGV[$inFile];
my $percentage = 5;
if ($#ARGV == 1) {
  $percentage = $ARGV[1];
}

our $exp;

do $ExpFileName;

my $errorRateFunc = sub {
  my ($self) = @_;
  
  return $self->getErrorRate();
};

my $logPFunc = sub {
  my ($self) = @_;
  
  return $self->getLogP();
};

my $AveragesTable = $exp->loadResultsFromFiles();

print "Comparing Error Rate\n******************\n";
compareAllModelsInAllProportions($errorRateFunc,$AveragesTable);
print "Comparing LogScore\n******************\n";
compareAllModelsInAllProportions($logPFunc,$AveragesTable);

sub compareAllModelsInAllProportions {
  my ($comparisonFunc,$AveragesTable) = @_;

  my $models = $AveragesTable->getModels();
  my $proportionList = $AveragesTable->getProportions();
  
  foreach my $proportion (@$proportionList) {
    print "******\n Results with proportion: $proportion\n *******\n";
    my $visitedModels = {};
    foreach my $m1 (@$models) {
      $visitedModels->{$m1} = 1;
      foreach my $m2 (@$models) { 
	if (!$visitedModels->{$m2}) {
	  compareModels($exp,$AveragesTable,$m1,$m2,$proportion,$comparisonFunc);
	}
      }
    }
  }
}

sub compareModels {
  my ($exp,$AveragesTable,$m1,$m2,$proportion,$comparisonFunc) = @_;
  
  my $m2BetterThanm1 = directionallyCompareModels($exp,$AveragesTable,$m1,$m2,$proportion,$comparisonFunc);
  my $m1BetterThanm2 = directionallyCompareModels($exp,$AveragesTable,$m2,$m1,$proportion,$comparisonFunc);

  if ($m1BetterThanm2>$m2BetterThanm1) {
    print "$m1 > $m2: $m1BetterThanm2 - $m2 > $m1: $m2BetterThanm1\n";
  } elsif ($m1BetterThanm2<=$m2BetterThanm1) {
    print "$m2 > $m1: $m2BetterThanm1 - $m1BetterThanm2\n";
  }
}


sub directionallyCompareModels {
  my ($exp,$AveragesTable,$m1,$m2,$proportion,$comparisonFunc) = @_;
  
  # Calculate the datasets in which both models have been run
  my $datasets1and2 = calculateDatasetIntersection($exp,$m1,$m2);
  my $counter = 0;
  foreach my $dataset (@$datasets1and2) {
    #      print "$dataset\n";
    $counter += compareModelsInDatasetAndProportion($exp,$AveragesTable,$m1,$m2,$dataset,$proportion,$comparisonFunc);
  }
  return $counter;
}

sub calculateDatasetIntersection{
  my ($exp,$modelA,$modelB) = @_;
  
  my $datasetsA = $exp->getDatasetsByInducer($modelA);
  #print "Datasets for inducer $modelA -> [".join(',',@$datasetsA)."]\n";
  
  my $datasetsB = $exp->getDatasetsByInducer($modelB);
  #print "Datasets for inducer $modelB -> [".join(',',@$datasetsB)."]\n";

  my $datasetsAandB = [];
  my %count = ();
  foreach my $element (@$datasetsA, @$datasetsB) { $count{$element}++ }
  foreach my $element (keys %count) {
    if ($count{$element} > 1) {
      push @$datasetsAandB, $element;
     }
  }
  my $datasetCount = $#{@$datasetsAandB}+1;
  #print "\nComparing $modelA with $modelB over $datasetCount datasets \n";
  
  return $datasetsAandB;
}

sub compareModelsInDatasetAndProportion {
  my ($exp,$AveragesTable,$m1,$m2,$dataset,$proportion,$comparisonFunc) = @_;
  
  my $results1 = $AveragesTable->getResultsByDatasetModelAndProportion($dataset,$m1,$proportion);
  my $results2 = $AveragesTable->getResultsByDatasetModelAndProportion($dataset,$m2,$proportion);
  my $ERdifference = [];
  my $i = 0 ;
  print "m1=$m1\nm2=$m2\n";
  foreach my $result1 (@$results1) {
    #print "Result1: $result1\n";
    #print "result2 = ".$results2->[$i]." \n";
    push @$ERdifference,(&$comparisonFunc($result1) - &$comparisonFunc($results2->[$i]));
    $i++;
  }
  
  my $UValue = calculateUValue($ERdifference);
  my $n = scalar(@$ERdifference);
  my $U99 = Statistics::Distributions::tdistr($n-1,$percentage/100);
  #print "n:$n  U: $UValue c:$U99\n";
  my $result = 0;
  if ($UValue>$U99) {
    print "$dataset: $m2 sign. better than $m1 at $percentage%\n";
    $result = 1;
  } else {
    #print "No sign. difference\n";
  }
  #print join(",",@$ERdifference)."\n\n";
  return $result;
}

sub calculateUValue {
  my ($ERdifference) = @_;

  my $n = scalar(@$ERdifference);
  my $sum = 0;
  foreach my $x (@$ERdifference) {
    $sum += $x;
  }
  my $xav = $sum / $n;
  my $sn2 = 0;
  foreach my $x (@$ERdifference) {
    $sn2 += ($x - $xav)*($x - $xav);
  }
  #print join(",",@$ERdifference)."\n\n";
  #print "sn2:$sn2\n";

  if ($sn2==0) {
    return 0;
  }
  return (sqrt($n)*$xav)/(sqrt($sn2/($n-1)));
}




















