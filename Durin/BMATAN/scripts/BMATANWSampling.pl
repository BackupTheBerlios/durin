# Tests Kruskal functionality
use FlexibleIO::System;
use Data::MemoryTable;
use IO::File;
use BMATAN::BMATANInducer;
use Classification::Experimentation::ModelApplier;
use Process::Sampler;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Data::FileTable->read($file);
$file->close();

for ($i=1; $i < 10; $i++)
{ 
  #print "Dataset loaded. Splitting\n";
  my $splitter = new Process::Sampler->new();
  my ($input) = {};
  $input->{TABLE} = $table;
  my $percent =  $i/10;
  $input->{PERCENTAGE} = $percent;
  $splitter->setInput($input);
  $splitter->run();
  my $output = $splitter->getOutput();
  my $train = $output->{TRAIN};
  my $test = $output->{TEST};
  
  my $BMATANI = BMATAN::BMATANInducer->new();
  $BMATANI->setInput($train);
  $BMATANI->run();
  my $BMATAN = $BMATANI->getOutput();
  my $applier = Classification::Experimentation::ModelApplier->new();
  my (%input);
  $input->{TABLE} = $test;
  $input->{MODEL} = $BMATAN;
  $applier->setInput($input);
  $applier->run();
  my $pair = $applier->getOutput();
  print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
  print "Train = $percent Accuracy = ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";
}  

print "Done\n";
