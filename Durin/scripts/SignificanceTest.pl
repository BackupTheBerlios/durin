#!/usr/bin/perl -w 

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

$ExpFileName = $ARGV[$inFile];
my $percentage = 5;
if ($#ARGV == 1) {
  $percentage = $ARGV[1];
}

our $exp;

do $ExpFileName;

my $AveragesTable = $exp->loadResultsFromFiles();

my $models = $AveragesTable->getModels();
my $proportionList = $AveragesTable->getProportions();

foreach $proportion (@$proportionList) {
  print "Results with proportion: $proportion\n";
  foreach my $m1 (@$models) {
    foreach my $m2 (@$models) { 
      if (!($m1 eq $m2)) {
	compareModels($exp,$AveragesTable,$m1,$m2,$proportion);
      }
    }
  }
}

sub compareModels {
  my ($exp,$AveragesTable,$m1,$m2,$proportion) = @_;

  # Calculate the datasets in which both models have been run
  my $datasets1and2 = calculateDatasetIntersection($exp,$m1,$m2);
  
  foreach $dataset (@$datasets1and2) {
    #      print "$dataset\n";
    compareModelsInDatasetAndProportion($exp,$AveragesTable,$m1,$m2,$dataset,$proportion);
  }
}

sub calculateDatasetIntersection{
  my ($exp,$modelA,$modelB) = @_;
  
  my $datasetsA = $exp->getDatasetsByInducer($modelA);
  #print "Datasets for inducer $modelA -> [".join(',',@$datasetsA)."]\n";
  
  my $datasetsB = $exp->getDatasetsByInducer($modelB);
  #print "Datasets for inducer $modelB -> [".join(',',@$datasetsB)."]\n";

  my $datasetsAandB = [];
  %count = ();
  foreach my $element (@$datasetsA, @$datasetsB) { $count{$element}++ }
  foreach my $element (keys %count) {
    if ($count{$element} > 1) {
      push @$datasetsAandB, $element;
     }
  }
  my $datasetCount = $#{@$datasetsAandB}+1;
  print "\nComparing $modelA with $modelB over $datasetCount datasets \n";
  
  return $datasetsAandB;
}

sub compareModelsInDatasetAndProportion {
  my ($exp,$AveragesTable,$m1,$m2,$dataset,$proportion) = @_;
  
  my $results1 = $AveragesTable->getResultsByDatasetModelAndProportion($dataset,$m1,$proportion);
  my $results2 = $AveragesTable->getResultsByDatasetModelAndProportion($dataset,$m2,$proportion);
  my $ERdifference = [];
  my $i = 0 ;
  foreach my $result1 (@$results1) {
    push @$ERdifference,($result1->getErrorRate() - $results2->[$i]->getErrorRate());
    $i++;
  }
  
  my $UValue = calculateUValue($ERdifference);
  my $n = scalar(@$ERdifference);
  my $U99 = Statistics::Distributions::tdistr($n-1,$percentage/100);
  #print "n:$n  U: $UValue c:$U99\n";
  if ($UValue>$U99) {
    print "$dataset: $m2 sign. better than $m1 at $percentage%\n";
  } else {
    #print "No sign. difference\n";
  }
  #print join(",",@$ERdifference)."\n\n";
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




















