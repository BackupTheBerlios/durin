# Tests Kruskal functionality
use FlexibleIO::System;
use Data::MemoryTable;
use IO::File;
use BMATAN::BayesianTANInducer;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Data::FileTable->read($file);
$file->close();

print "CTS loaded\n";

my $TANI = BMATAN::BayesianTANInducer->new();
$TANI->setInput($table);
$TANI->run();


#my $TAN = $TANI->getOutput();
#my $Tree = $TAN->getTree();
#print "The directed spanning tree is:\n";
#@edges = @{$Tree->getEdges()};
#foreach $p (@edges)
#{
#    print ${@$p}[0],",",${@$p}[1], "\n";
#}

print "Done\n";
