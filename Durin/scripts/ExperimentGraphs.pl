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

do $ExpFileName;

my $interactive = 1;

if ($ARGV[$generatePostcriptPos] == 1)
  {
    $interactive = 0;
  }

my $AveragesTable = Durin::Classification::Experimentation::CompleteResultTable->new();
my $mainDir = $ENV{PWD};
$destinationDir = $resultDir.$ExpName;
print $destinationDir."\n";
chdir $destinationDir;
foreach my $datasetInfo (@list)
  {
    my $dataset = $datasetInfo->[0];
    if (-e "$dataset.out")
      {
	print "Taking info from to dataset $dataset\n";
	Process($dataset,$AveragesTable);
      } 
    else
      {
	print "Dataset $dataset has not yet been calculated\n";
      }
  }
chdir $mainDir;

$AveragesTable->compressRuns();
DrawPictures($AveragesTable);

print "Done\n";

sub Process
  {
    my ($dataset,$AveragesTable) = @_;
    
    my $file = new IO::File;
    $file->open("<$dataset.out") or die "Unable to open $dataset.out\n";
    
    # read the headers (the field names)
    my $line = $file->getline();
    my @decompLine = split(/,/,$line);
    if (!($decompLine[0] eq "Fold"))
      {
	die "File $dataset.out has not the format required\n";
      }
    
    my $i = 2;
    my $modelList = ();
    while ($i < $#decompLine)
      {
	push @$modelList,(substr($decompLine[$i],2));
	$i += 4;
      }
    
    #my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
    do 
      {
	$line = $file->getline();
	my @array = split(/,/,$line);
	$i = 0;
	my $runId = $array[0];
	my $proportion = $array[1];
	#print "Proportion: $proportion\n";
	foreach $modelName (@$modelList)
	  {
	    my $OKs = $array[$i * 4 + 2];
	    my $Wrongs = $array[$i * 4 + 3];
	    my $PLog = $array[$i *4 + 5];
	    #print "Next One: $modelName $runId $OKs $Wrongs $PLog\n";
	    #getc;
	    my $PMA = Durin::ProbClassification::ProbModelApplication->new();
	    $PMA->setNumOKs($OKs);
	    $PMA->setNumWrongs($Wrongs);
	    $PMA->setLogP($PLog);

	    # Check for CV results
	    
	    my ($idNum,$foldNum);
	    if ($runId =~ /(.*)\.(.*)/)
	      {
		$idNum = $1;
		$foldNum = $2;
	      }
	    else
	      {
		$idNum = $runId;
		$foldNum = 0;
	      }
	    $AveragesTable->addResult($dataset,$idNum,$foldNum,$proportion,$modelName,$PMA);
	    $i++; 
	  }
      }
    until ($file->eof()); 
    $file->close();
  }

sub DrawPictures
  {
    my ($AveragesTable) = @_;
    
    my $models = $AveragesTable->getModels();
    my @listDevices = ();
    
    my $window = PDL::Graphics::PGPLOT::Window->new(Device => "\@:0.0/XSERVE");
    pgend();
    my $i = 0;
    my $numGraphs = scalar(@$models) * (scalar(@$models) - 1) / 2; 
    my $status = pgopen("\@:0.0/XSERVE");
    $numGraphs = 1;
    while (($i < $numGraphs-1) && ($status > 0))
      {
	push @listDevices,($status); 
	$i++;
	$status = pgopen("\@:0.0/XSERVE");	    
      }
    if (($i >= $numGraphs-1))
      {
	push @listDevices,($status); 
      }
    print "Created all of them ".join(",",@listDevices)."\n";
    $i = 0;
    $window->env(0,5,0,5,0,-2); # set world-window size 
    foreach my $m1 (@$models)
      {
	foreach my $m2 (@$models)
	  {
	    if ($m1 lt $m2)
	      {


		if ($interactive) {
		  pgslct($listDevices[$i % ($#listDevices + 1)]);
		  DifferencePlot("ER",$m1,$m2,$AveragesTable);
		  $i++;
		  pgslct($listDevices[$i % ($#listDevices + 1)]);
		  $i++;
		  DifferencePlot("LogP",$m1,$m2,$AveragesTable);
		} else {
		  my $id = pgopen("ER$m2-$m1.ps/VCPS");
		  pgslct($id);
		  DifferencePlot("ER",$m1,$m2,$AveragesTable);
		  pgend();
		  $i++;
		  $id = pgopen("LogP$m2-$m1.ps/VCPS");
		  pgslct($id);
		  $i++;
		  DifferencePlot("LogP",$m1,$m2,$AveragesTable);
		  pgend();
		}
	      }
	  }
      }
  }

sub DifferencePlot {
  my ($plotType,$modelA,$modelB,$AveragesTable) = @_;
  
  my $proportionList = $AveragesTable->getProportions();
  my ($x,$subsOrdIndx) = preparateDifferencePlot($plotType,$modelA,$modelB,$AveragesTable,$proportionList->[0]);
  my $color = 3;
  foreach my $proportion (@$proportionList) {
    DifferencePlotByProportion($plotType,$modelA,$modelB,$AveragesTable,$x,$subsOrdIndx,$proportion,$color);
    $color++;
  }
}

sub preparateDifferencePlot {
  my ($plotType,$modelA,$modelB,$AveragesTable,$proportion) = @_;
  
  my $numDatasets = scalar(@{$AveragesTable->getDatasets()});
  
  my $x = sequence($numDatasets);
  my $zeroLine = zeroes($numDatasets);
  my $plotList = [];
  $color = 2;

  my $subs = CalculateSubs($plotType,$modelA,$modelB,$AveragesTable,$proportion);
 
  my $min = min($subs);
  #if ($min < -100)
  #  {
  #    $min = -100;
  #  }
  my $max = max($subs);
  #if ($max > 100)
  #  {
  #    $max = 100;
  #  }
  my $margin = ($max-$min) * 0.4;
  my $step = ($max-$min)*0.1;
  $min = $min - $margin;
  $max = $max + $margin;
  my $subsOrdIndx = $subs->qsorti;
  #dev "/XSERVE";  # Open plot device 
  pgpap(7,1); # set x-window size 
  #pgwnad(-1,16,$min,$max);
  env 0,$numDatasets-1,$min,$max,0,-2; # set world-window size 
  my $title = GetPlotTitle($plotType,$modelA,$modelB);
  pglab("Datasets","",$title);
  pgaxis("",0,$min,$numDatasets-1,$min,0,$numDatasets-1,1,$numDatasets+1,.5,.5,0,0,0);
  pgsch(.6);
  pgaxis("N",0,$min,0,$max,$min,$max,$step*2,2,.5,.5,0.5,-1,90);
  my $tick = 0;
  my $name;
  my $datasetList = $AveragesTable->getDatasets();
  foreach my $i ($subsOrdIndx->listindices())
    {
      $name = $datasetList->[$subsOrdIndx->at(($i))];
      pgtick(0,$min,$numDatasets-1,$min,$tick/($numDatasets-1),.5,.5,1,60,$name);
      $tick++;
    }
  line $x,$zeroLine,{COLOR => $color++};
  return ($x,$subsOrdIndx);
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
sub CalculateSubs {
  my ($plotType,$modelA,$modelB,$AveragesTable,$proportion) = @_;
  
  print "Proportion: $proportion\n";
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
  my ($plotType,$modelA,$modelB,$AveragesTable,$x,$subsOrdIndx,$proportion,$color) = @_;
  
  my $subs = CalculateSubs($plotType,$modelA,$modelB,$AveragesTable,$proportion);
  points $x,$subs->index($subsOrdIndx),{COLOR => $color,SYMBOL=>STAR,PLOTLINE=>1};
}
  
