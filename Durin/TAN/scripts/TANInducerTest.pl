# Tests Kruskal functionality
use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;
use Durin::TAN::FGGTANInducer;

my $inFileName = $ARGV[0]; 
$file = new IO::File;
$file->open("<$inFileName") or die "Unable to open input file: $inFileName\n";
my $table = Durin::Data::FileTable->read($file);

$file->close();

print "CTS loaded\n";

my $TANI = Durin::TAN::FGGTANInducer->new();
{
    my $input = {};
    $input->{TABLE} = $table;
    $TANI->setInput($input);
}
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
