# Tests Kruskal functionality
use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;

use Durin::TAN::LaplaceTANInducer;
use Durin::TAN::FGTANInducer;
use Durin::Classification::Experimentation::ModelApplier;
use Durin::PP::Sampling::Sampler;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table_total = Durin::Data::FileTable->read($file);
$file->close();

my $TANI = Durin::TAN::FGTANInducer->new();
my $STANI = Durin::TAN::LaplaceTANInducer->new();

my @resultList = ();
my $table;
if ($#ARGV > 1)
  {
    my $percent = $ARGV[2];
    my $splitter = new Durin::PP::Sampling::Sampler->new();
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


print "Comparing: FGTAN,LaplaceTAN\n";
for ($i=1; $i < 10; $i++)
  { 
    my $percent = ($i/10);
    #print "Dataset loaded. Splitting\n";
    my $comparisonTableRef = Iterate($table,$percent,10,[$TANI,$STANI]);
    
    push @resultList,@$comparisonTableRef;
  }

$file_name = $ARGV[1];
$file = new IO::File;
$file->open(">$file_name") or die "No pude\n";


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
    my $splitter = new Durin::PP::Sampling::Sampler->new();
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
	{
	  my $input = {};
	  $input->{TABLE} = $train;
	  $InductionMethod->setInput($train);
	}
	$InductionMethod->run();
	my $Model = $InductionMethod->getOutput();
	my $applier = Durin::Classification::Experimentation::ModelApplier->new();
	{
	  my $input = {};
	  $input->{TABLE} = $test;
	  $input->{MODEL} = $Model;
	  $applier->setInput($input);
	}
	$applier->run();
	my $pair = $applier->getOutput();
	print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
	print "Train = $percent Accuracy = ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";
	push @runResult,([$pair->[0],$pair->[1],(100 * $pair->[0])/($pair->[0] + $pair->[1])]);
      }  
    return (\@runResult);
  }
