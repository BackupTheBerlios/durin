# Tests Kruskal functionality
use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;
use Durin::TAN::TANInducer;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Durin::Data::FileTable->read($file);
$file->close();

print "CTS loaded\n";

my $TANI = Durin::TAN::TANInducer->new();
$TANI->setInput($table);
$TANI->run();
my $TAN = $TANI->getOutput();
my $Tree = $TAN->getTree();
print "The directed spanning tree is:\n";
@edges = @{$Tree->getEdges()};
foreach $p (@edges)
{
    print ${@$p}[0],",",${@$p}[1], "\n";
}

print "Done\n";
