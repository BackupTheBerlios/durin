# Tests Kruskal functionality
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

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Data::FileTable->read($file);
$file->close();
 
#my $BMATANI = BMATAN::BMATANInducer->new();
my $STANI = TAN::SmoothedTANInducer->new();
my $NBI = Process::NaiveBayes::NBInducer->new();
my $RSBMATANI = BMATAN::RealSmoothedBMATANInducer->new();

my @resultList = ();

for ($i=1; $i < 10; $i++)
  { 
    my $percent = ($i/10);
    #print "Dataset loaded. Splitting\n";
    my $comparisonTableRef = Iterate($table,$percent,10,[$NBI,$STANI,$RSBMATANI]);
    
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
    my $splitter = new PP::Sampling::Sampler->new();
    my ($input) = {};
    $input->{TABLE} = $table;
    $input->{PERCENTAGE} = $percent;
    $splitter->setInput($input);
    $splitter->run();
    my $output = $splitter->getOutput();
    my $train = $output->{TRAIN};
    my $test = $output->{TEST};
    my @runResult = ([$percent,$run]);
    
    foreach my $InductionMethod (@$methodListRef)
      {
	$InductionMethod->setInput($train);
	$InductionMethod->run();
	my $Model = $InductionMethod->getOutput();
	my $applier = Classification::Experimentation::ModelApplier->new();
	my (%input);
	$input->{TABLE} = $test;
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
