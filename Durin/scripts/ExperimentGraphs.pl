#!/usr/bin/perl -w 

# This scripts generates the comparison graphs for a 

use IO::File;
use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::CompleteResultTable;
use Durin::ProbClassification::ProbModelApplication;
use Durin::Utilities::MathUtilities;
use PDL::Graphics::PGPLOT;
use PDL;
use PGPLOT;
use PDL::Primitive;

if ($#ARGV < 0)
  {
    print "This script generates comparison graphs for the results of an experiment";
    die "Usage: ExperimentGraphs.pl experiment.exp [generatePostcripts]\n";
  }

my $inFilePos = 0;
my $generatePostcriptPos = 1;
my $ER = 1;
my $LOGP = 2;

$ExpFileName = $ARGV[$inFilePos];

our $exp;

do $ExpFileName;

my $interactive = 1;

if ($#ARGV > 0)
  {
    if ($ARGV[$generatePostcriptPos] == 1)
      {
	$interactive = 0;
      }
  }

my $AveragesTable = $exp->loadResultsFromFiles();
$AveragesTable->compressRuns();
DrawPictures($exp,$AveragesTable);
print "Done\n";


sub DrawPictures
  {
    my ($exp,$AveragesTable) = @_;
    
    my $models = $AveragesTable->getModels();
    my @listDevices = ();
    
    my $dev = "\@:0.0/XSERVE";
    if ($interactive)
      {
	dev $dev;
	pgend();
      }
    else
      {
	$dev = "/VCPS";
	dev $dev;
	pgend();
      }
    my $i = 0;
    my $numGraphs = scalar(@$models) * (scalar(@$models) - 1) / 2;  
    my $status;
    if ($interactive) {
      $status = pgopen("$dev");
    } else {
      $status = dev $dev;
    }
    push @listDevices,$status; 
    $i = 0;
    pgslct($status);
    env (0,5,0,5,0,-2); # set world-window size 

    
    foreach my $m1 (@$models) {
      foreach my $m2 (@$models) {
	if (!($m1 eq $m2)) {
	  if ($interactive) {
	    #pgslct($listDevices[$i % ($#listDevices + 1)]);
	    pgslct($status);
	    DifferencePlot("ER",$m1,$m2,$exp,$AveragesTable);
	    pgslct($status);
	    DifferencePlot("LogP",$m1,$m2,$exp,$AveragesTable);
	  } else {
	    my $id = pgopen("ER$m2-$m1.ps/VCPS");
	    pgslct($id);
	    DifferencePlot("ER",$m1,$m2,$exp,$AveragesTable);
	    pgclos();
	    $i++;
	    $id = pgopen("LogP$m2-$m1.ps/VCPS");
	    pgslct($id);
	    $i++;
	    DifferencePlot("LogP",$m1,$m2,$exp,$AveragesTable);
	    pgclos();
	  }
	}
      }
    }
  }

sub DifferencePlot {
  my ($plotType,$modelA,$modelB,$exp,$AveragesTable) = @_;
  
  my $proportionList = $AveragesTable->getProportions();
  my ($datasets,$x,$subsOrdIndx,$colours) = preparateDifferencePlot($plotType,$modelA,$modelB,$exp,$AveragesTable,$proportionList->[0]);
 
  my $i = 0;
  foreach my $proportion (@$proportionList) {
    DifferencePlotByProportion($plotType,$modelA,$modelB,$datasets,$AveragesTable,$x,$subsOrdIndx,$proportion,$colours->[$i]);
    $i++;
  }
}

sub preparateDifferencePlot {
  my ($plotType,$modelA,$modelB,$exp,$AveragesTable,$proportion) = @_;

  # Determine the datasets where both inducers have been run
  
  my $datasetsA = $exp->getDatasetsByInducer($modelA);
  print "Datasets for inducer $modelA -> [".join(',',@$datasetsA)."]\n";
  
  my $datasetsB = $exp->getDatasetsByInducer($modelB);
  print "Datasets for inducer $modelB -> [".join(',',@$datasetsA)."]\n";
  
  
  my $datasetsAandB = [];
  my $datasetsHash = {};
  %count = ();
  foreach my $element (@$datasetsA, @$datasetsB) { $count{$element}++ }
  foreach my $element (keys %count) {
    if ($count{$element} > 1) {
      push @$datasetsAandB, $element;
      $datasetsHash->{$element} = 1;
    }
  }
  my $numDatasets = scalar(@$datasetsAandB);

  print "Num datasets: $numDatasets -> [".join(',',@$datasetsAandB)."]\n";

  my $x = sequence($numDatasets);
  my $zeroLine = zeroes($numDatasets);
  my $plotList = [];
  $color = 2;

  
  my ($min,$max,$subsOrdIndx,$names,$line_styles,$colours) = @{CalculateMinMax($plotType,$modelA,$modelB,$datasetsHash,$AveragesTable)};
  
  my $margin = ($max-$min) * 0.1;
  my $step = ($max-$min) * 0.1; 
  
  $min = $min - $margin;
  $max = $max + $margin;
  pgpap(7,1); # set x-window size 
  env 0,$numDatasets-1,$min,$max,0,-2; # set world-window size 
  my $title = GetPlotTitle($plotType,$modelA,$modelB);
  pglab("Datasets","",$title);
  pgaxis("",0,$min,$numDatasets-1,$min,0,$numDatasets-1,1,$numDatasets+1,.5,.5,0,0,0);
  pgsch(.6);
  pgaxis("N",0,$min,0,$max,$min,$max,$step*2,2,.5,.5,0.5,-1,90);
  my $tick = 0;
  my $name;
  my $datasetList = $AveragesTable->getDatasets();
  print "SubsOrdIndx = $subsOrdIndx\n";
  foreach my $i ($subsOrdIndx->listindices()) {
    $name = $datasetList->[$subsOrdIndx->at(($i))];
    if ($datasetsHash->{$name}) {
      pgtick(0,$min,$numDatasets-1,$min,$tick/($numDatasets-1),.5,.5,1,60,$name);
      $tick++;
    }
  }
  legend $names, 1, $max-$margin, {LineStyle => $line_styles, Colour => $colours};
  line $x,$zeroLine,{COLOR => $color++};
  return ($datasetsHash,$x,$subsOrdIndx,$colours);
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

sub CalculateMinMax {
  my ($plotType,$modelA,$modelB,$datasets,$AveragesTable) = @_;

  my $min = exp(1000);
  my $max = -exp(1000);
  my $subs;
  my $subsOrdIndx;
  my $proportionList = $AveragesTable->getProportions();

  my $color = 3;
  my @colours = ();
  my @line_styles= ();
  my @names = ();
  my $datasetList = $AveragesTable->getDatasets();
  foreach my $proportion (@$proportionList) {
    $subs = CalculateSubs($plotType,$modelA,$modelB,$AveragesTable,$proportion);
    $subsOrdIndx = $subs->qsorti;
    print "$subs , $max\n";
    my $j=0;
    foreach my $i ($subsOrdIndx->listindices()) {
      $name = $datasetList->[$subsOrdIndx->at(($i))];
      if ($datasets->{$name}) {
	if ($max < $subs->at($subsOrdIndx->at(($i)))) {
	  $max = $subs->at($subsOrdIndx->at(($i)));
	} 
	if ($min > $subs->at($subsOrdIndx->at(($i)))){
	  $min = $subs->at($subsOrdIndx->at(($i)));
	}
      }  
    }
    #$min = Durin::Utilities::MathUtilities::min(min($subs),$min);
    #$max = Durin::Utilities::MathUtilities::max(max($subs),$max);
    push @names,($proportion*100)." %";
    push @colours,$color++;
    push @line_styles,'Solid';
  }
  
  print "Min:$min Max:$max\n";
  if ($min < -100) {
    $min = -100
  }
  if ($max > 100) {
    $max = 100;
  }

  #print "Subs = $subs SubsOrdIndx : $subsOrdIndx \n";
  return [$min,$max,$subsOrdIndx,\@names,\@line_styles,\@colours];
}
 

sub CalculateSubs {
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
    }
  my $subs = (($piddleA - $piddleB) / $piddleA) * 100;
  
  return $subs;
}

sub DifferencePlotByProportion {
  my ($plotType,$modelA,$modelB,$datasets,$AveragesTable,$x,$subsOrdIndx,$proportion,$color) = @_;
  
  my $subs = CalculateSubs($plotType,$modelA,$modelB,$AveragesTable,$proportion);
  my $selectedSubs = zeroes(scalar(keys %$datasets));
  my $datasetList = $AveragesTable->getDatasets();
  my $j=0;
  foreach my $i ($subsOrdIndx->listindices()) {
    $name = $datasetList->[$subsOrdIndx->at(($i))];
    if ($datasets->{$name}) {
      set $selectedSubs,$j,$subs->at($subsOrdIndx->at(($i)));
      $j++;
    }
  }  
  points $x,$selectedSubs,{COLOR => $color,SYMBOL=>STAR,PLOTLINE=>1};
}
  
