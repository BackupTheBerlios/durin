# Calculates the comparison between different learning methods 
# usage:
# perl -w <my> in.std out [num_splits] [num_reps] [initial_sampling]

use FlexibleIO::System;
use Data::MemoryTable;
use IO::File;

use BMATAN::BMATANInducer;
use BMATAN::SmoothedBMATANInducer;
use BMATAN::RealSmoothedBMATANInducer;
use TAN::SmoothedTANInducer;
use Process::NaiveBayes::NBInducer;
use Classification::Experimentation::ModelApplier;
use PP::Sampling::Sampler;
use PP::Discretization::Discretizer;
use TAN::TANInducer;
use PP::Discretization::DiscretizationApplier;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table_total = Data::FileTable->read($file);
$file->close();
 
my $table;

# A first step of sampling if it is required by the user

my ($num_splits,$num_reps);

if ($#ARGV > 1)
  {
    $num_splits = $ARGV[2];
    if ($#ARGV > 2)
      {
	$num_reps = $ARGV[3];
	if ($#ARGV > 3)
	  {
	    my $percent = $ARGV[4];
	    my $splitter = new PP::Sampling::Sampler->new();
	    my ($input) = {};
	    $input->{TABLE} = $table_total;
	    $input->{PERCENTAGE} = $percent;
	    #$input->{FUNCTION} = sub
	    #      {
	    #	my ($row) = @_;
	    #	
	    #	print "Hola @$row\n";
	    #      };
	    
	    $splitter->setInput($input);
	    $splitter->run();
	    my $output = $splitter->getOutput();
	    $table = $output->{TRAIN};
	  }
	else
	  {
	    $table = $table_total;
	  }
      }
    else
      {
	$num_reps = 10;
      }
  }
else
  {
    $num_splits = 10;
  }
	
#my $BMATANI = BMATAN::BMATANInducer->new();

my $NBI = Process::NaiveBayes::NBInducer->new();
my $TANI = TAN::TANInducer->new();
my $STANI = TAN::SmoothedTANInducer->new();
my $RSBMATANI = BMATAN::RealSmoothedBMATANInducer->new();

my @resultList = ();

for ($i=1; $i <= $num_splits; $i++)
  { 
    my $percent = ($i/($num_splits+1));
    #print "Dataset loaded. Splitting\n";
    my $comparisonTableRef = Iterate($table,$percent,$num_reps,[$NBI,$TANI,$STANI,$RSBMATANI]);
    
    push @resultList,@$comparisonTableRef;
  }

$file_name =$ARGV[1];
$file = new IO::File;
$file->open(">$file_name") or die "No pude\n";

print "Testing NB,TAN,BMATAN\n";
foreach my $run_result (@resultList)
  {
    foreach my $method_result (@$run_result)
      {
	print $file (join(",",@$method_result).";");
      }
    print $file "\n";
  }
$file->close();


sub Iterate
  {
    my ($table,$percent,$numRuns,$methodListRef) = @_;
    
    my ($i,@resultsList);
    @resultsList =();
    for ($i = 1; $i <= $numRuns; $i++)
      {
	my $comparisonTableRef = Compare($table,$percent,$i,$methodListRef);
	
	push @resultList,($comparisonTableRef);
      }
    return \@resultsList;
  }

sub Compare
  {
    my ($table,$percent,$run,$methodListRef) = @_;
    my $splitter = PP::Sampling::Sampler->new();
    my ($input) = {};
    $input->{TABLE} = $table;
    $input->{PERCENTAGE} = $percent;
    $splitter->setInput($input);
    $splitter->run();
    my $output = $splitter->getOutput();
    my $train = $output->{TRAIN};
    my $test = $output->{TEST};
    my @runResult = ([$percent,$run]);
    
    my $Discretizer = PP::Discretization::Discretizer->new();
    my $Din;
    $Din->{TABLE} = $train;
    $Din->{NUMINTERVALS} = 5;
    $Din->{DISCMETHOD} = "Frequency";
    $Discretizer->setInput($Din);
    $Discretizer->run();
    my $Dout = $Discretizer->getOutput();
    my $DTrain = $Dout->{TABLE};
    my $DA = PP::Discretization::DiscretizationApplier->new();
    my $DAin;
    $DAin->{DISC} = $Dout->{DISC};
    $DAin->{TABLE} = $test;
    $DA->setInput($DAin);
    $DA->run();
    my $DTest = $DA->getOutput();
    foreach my $InductionMethod (@$methodListRef)
      {
	$InductionMethod->setInput($DTrain);
	$InductionMethod->run();
	my $Model = $InductionMethod->getOutput();
	my $applier = Classification::Experimentation::ModelApplier->new();
	my (%input);
	$input->{TABLE} = $DTest;
	$input->{MODEL} = $Model;
	$applier->setInput($input);
	$applier->run();
	my $pair = $applier->getOutput();
	print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
	print "Train = $percent Accuracy = ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";
	push @runResult,([$pair->[0],$pair->[1],(100 * $pair->[0])/($pair->[0] + $pair->[1])]);
      }  
    return (\@runResult);
  }
