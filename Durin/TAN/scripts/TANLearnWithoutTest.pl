# Tests TANInducer functionality

use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;
use Durin::TAN::CoherentCoherentTANInducer;
use Durin::Classification::Experimentation::ModelApplier;

print "Opening input file\n";

my $file_name = $ARGV[0];
my $file = new IO::File;
$file->open("<$file_name") or die "Unable to open $file_name\n";
my $table = Durin::Data::FileTable->read($file);
$file->close();

print "Learning bayesian network\n";

my $TANI = Durin::TAN::CoherentCoherentTANInducer->new();
{
  my $Input = {};
  $Input->{TABLE} = $table;
  $TANI->setInput($Input);
}
$TANI->run();
my $TAN = $TANI->getOutput();

print "Writing bayesian network in Netica format\n";
my $outFileName = $ARGV[1];
my $outFile = new IO::File;
$outFile->open(">$outFileName") or die "Unable to open $outFileName\n";
$TAN->write($outFile,"Netica");
$outFile->close();

print "Done\n";



#my $Tree = $TAN->getTree();
#print "The directed spanning tree is:\n";
#@edges = @{$Tree->getEdges()};
#foreach $p (@edges)
#{
#    print ${@$p}[0],",",${@$p}[1], "\n";
#if ($Tree->areConnected(${@$p}[0],${@$p}[1]) eq FALSE)
#{
#    print ${@$p}[0],",",${@$p}[1], " are not connected\n";
#}
#}
#print "Now we are going to classify:\n";
#
#my $applier = Durin::Classification::Experimentation::ModelApplier->new();
#my (%input);
#$input->{TABLE} = $table;
#$input->{MODEL} = $TAN;
#$applier->setInput($input);
#$applier->run();
#my $pair = $applier->getOutput();
#print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
#print "Accuracy: ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";

