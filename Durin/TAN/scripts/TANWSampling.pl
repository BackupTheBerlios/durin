# Tests Kruskal functionality
use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;
use Durin::TAN::TANInducer;
use Durin::Classification::Experimentation::ModelApplier;
use Process::Sampler;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Durin::Data::FileTable->read($file);
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
  
  my $TANI = Durin::TAN::TANInducer->new();
  $TANI->setInput($train);
  $TANI->run();
  my $TAN = $TANI->getOutput();
  my $Tree = $TAN->getTree();
  #print "The directed spanning tree is:\n";
  #@edges = @{$Tree->getEdges()};
  #foreach $p (@edges)
  #  {
  #    print ${@$p}[0],",",${@$p}[1], "\n";
  #if ($Tree->areConnected(${@$p}[0],${@$p}[1]) eq FALSE)
  #{
  #  print ${@$p}[0],",",${@$p}[1], " are not connected\n";
  #}
  #}
  #print "Now we are going to classify:\n";
  
  my $applier = Durin::Classification::Experimentation::ModelApplier->new();
  my (%input);
  $input->{TABLE} = $test;
  $input->{MODEL} = $TAN;
  $applier->setInput($input);
  $applier->run();
  my $pair = $applier->getOutput();
  print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
  print "Train = $percent Accuracy = ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";
}  

print "Done\n";
