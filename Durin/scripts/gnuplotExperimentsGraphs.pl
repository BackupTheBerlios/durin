#!/usr/bin/perl -w 

# This scripts generates the comparison graphs for an experiment using gnuplot

use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::CompleteResultTable;
use Durin::ProbClassification::ProbModelApplication;
use Durin::Utilities::MathUtilities;

use PDL::Graphics::PGPLOT;
use PDL;
use PGPLOT;
use PDL::Primitive;
use IO::File;
use File::Temp;
use Text::Template;
use Env;

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

our $exp;

do $ExpFileName;
my $AveragesTable = $exp->loadResultsFromFiles();
$AveragesTable->compressRuns();
DrawPictures($exp,$AveragesTable);
print "Done\n";


sub DrawPictures
  {
    my ($exp,$AveragesTable) = @_;
    
    my $datasets = $AveragesTable->getDatasets();
    my $models = $AveragesTable->getModels();
    my $proportionList = $AveragesTable->getProportions();
    
    foreach my $m1 (@$models) {
      foreach my $m2 (@$models) {
	if (!($m1 eq $m2)) {
	  # Determine the datasets where both models have been run
	  
	  my $datasetsHash = calculateDatasetIntersection($m1,$m2,$exp);
	  print "$m1-$m2\n";
	  ComparisonPlot("ER",$m1,$m2,$exp,$AveragesTable,$datasets,$datasetsHash,$proportionList);
	  ComparisonPlot("LogP",$m1,$m2,$exp,$AveragesTable,$datasets,$datasetsHash,$proportionList);
	  ComparisonPlot("AUC",$m1,$m2,$exp,$AveragesTable,$datasets,$datasetsHash,$proportionList);
	}
      }
    }
  }

sub ComparisonPlot {
  my ($plotType,$modelA,$modelB,$exp,$AveragesTable,$datasets,$datasetsHash,$proportionList) = @_;
  
  #my $i = 0;
  foreach my $proportion (@$proportionList) {
    ComparisonPlotByProportion($plotType,$modelA,$modelB,$datasets,$datasetsHash,$AveragesTable,$proportion);
    # $i++;
  }
}

sub calculateDatasetIntersection {
  my ($modelA,$modelB,$exp) = @_;
  
  my $datasetsA = $exp->getDatasetsByInducer($modelA);
  print "Datasets for inducer $modelA -> [".join(',',@$datasetsA)."]\n";
  
  my $datasetsB = $exp->getDatasetsByInducer($modelB);
  print "Datasets for inducer $modelB -> [".join(',',@$datasetsB)."]\n";
  
  my $datasetsAandB = [];
  my $datasetsHash = {};
  my %count = ();
  foreach my $element (@$datasetsA, @$datasetsB) { $count{$element}++ }
  foreach my $element (@$datasetsA) {
    if ($count{$element} > 1) {
      push @$datasetsAandB, $element;
      $datasetsHash->{$element} = 1;
    }
  }
  print "Datasets for both: [".join(',',@$datasetsAandB)."]\n";
  return $datasetsHash;
}

sub GetPlotTitle {
  my ($plotType,$modelA,$modelB) = @_;
  if ($plotType eq "LogP")
    {
      return "Improvement in LogP of ".$modelB." over ".$modelA." (in percent)";
    }
  elsif ($plotType eq "ER")
    {
      return "Improvement in error rate of ".$modelB." over ".$modelA." (in percent)";
    }
}

sub getModelResults {
  my ($plotType,$modelA,$modelB,$AveragesTable,$proportion) = @_;
  
  #print "Proportion: $proportion\n";
  my ($piddleA,$piddleB);
  if ($plotType eq "LogP")
    {
      $piddleA = $AveragesTable->getAvLogPDatasets($modelA,$proportion);
      $piddleB = $AveragesTable->getAvLogPDatasets($modelB,$proportion);
    } elsif ($plotType eq "ER") {
      $piddleA = $AveragesTable->getAvERDatasets($modelA,$proportion);
      $piddleB = $AveragesTable->getAvERDatasets($modelB,$proportion);
    } elsif ($plotType eq "AUC") {
      $piddleA = $AveragesTable->getAvAUCDatasets($modelA,$proportion);
      $piddleB = $AveragesTable->getAvAUCDatasets($modelB,$proportion);
    }
  return [$piddleA,$piddleB];
}

sub ComparisonPlotByProportion {
  my ($plotType,$modelA,$modelB,$datasets,$datasetsHash,$AveragesTable,$proportion) = @_;
  
  # get Model A and B results
  my ($piddleA,$piddleB) = @{getModelResults($plotType,$modelA,$modelB,$AveragesTable,$proportion)};
  
  # transform plot data into string
  my $data = "";
  my $i = 0;
  #print "m1\n";
  my $max_x;
  my $max_y;
  my $min_x;
  my $min_y;
  my $init = 0;
  #print "m2\n";
  my $logPoutliers = [];
  foreach my $dataset (@$datasets){
    if (defined $datasetsHash->{$dataset}) {
      if ($init == 0) {
	$max_x = $piddleA->at($i);
	$min_x = $piddleA->at($i);
	$max_y = $piddleB->at($i);
	$min_y = $piddleB->at($i);
	$init = 1;
      }
      #print "$i\n";
      my $x = $piddleA->at($i);
      my $y = $piddleB->at($i);
      if ($x > 1000) {
	if ($y > 1000) {
	  print "There is a weird two sided outlier?\n";
	} else {
	  push @$logPoutliers,["x",$y];
	}
      } else {
	if ($y > 1000) { 
	  push @$logPoutliers,["y",$x];
	} else {
	  $max_x = $x if $x > $max_x; 
	  $min_x = $x if $x < $min_x;
	  $max_y = $y if $y > $max_y; 
	  $min_y = $y if $y < $min_y;
	  $data = $data."".$x." ".$y."\n";
	}
      }
    }
    $i++;
  }
  my $multiplied_x = 0;
  my $multiplied_y = 0;
  foreach my $outlier (@$logPoutliers) {
    if ("x" eq $outlier->[0]) {
      if (!$multiplied_x) {
	$max_x *= 1.1;
	$multiplied_x = 1;
      }
      $data = $data."".$max_x." ".$outlier->[1]."\n";
    } else { 
      if (!$multiplied_y) {
	$max_y *= 1.1;
	$multiplied_y = 1;
      }
      $data = $data."".$outlier->[1]." ".$max_y."\n";
    }
  }
  $data = $data."e\n";
  
  # generate gnuplot file
  
  my $tmpFile = File::Temp->new(DIR=>'/tmp',
				SUFFIX => '.gnuplot');
  
  my $template = Text::Template->new(SOURCE => "$DURIN_HOME/scripts/plot.gnuplot.tmpl")
    or die "Couldn't construct template: $Text::Template::ERROR";
  
  # It is a squared plot. Collapse the max's and min's.
  my $min = $min_x < $min_y ? $min_x : $min_y;
  my $max = $max_x < $max_y ? $max_y : $max_x;
  my %vars = (x_size => 2,
	      y_size => 2,
	      x_range_min => $min-($max-$min)*0.1,
	      x_range_max => $max+($max-$min)*0.1,
	      y_range_min => $min-($max-$min)*0.1,
	      y_range_max => $max+($max-$min)*0.1,
	      output => "$modelA-$modelB-$plotType-$proportion.eps",
	      data => $data
	     );
  #print "Template:".$template."\n";
  my $result = $template->fill_in(HASH => \%vars);
  die "$Text::Template::ERROR\n"  if (!defined $result);
  print $tmpFile $result;
  system "gnuplot ".$tmpFile->filename;
}
