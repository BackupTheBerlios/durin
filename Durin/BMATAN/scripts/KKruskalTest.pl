# Tests Kruskal functionality
use FlexibleIO::System;
use Data::MemoryTable;
use IO::File;
use ProbClassification::ProbApprox::Counter;
use TAN::GraphConstructor;
use BMATAN::KKruskal;
use DataStructures::Graph;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Data::FileTable->read($file);
$file->close();

print "CTS loaded\n";

my $bc = ProbClassification::ProbApprox::Counter->new();
$bc->setInput($table);
$bc->run();
my @tablesRef = @{$bc->getOutput()};

my $gcons = TAN::GraphConstructor->new();
my ($Input);
$Input->{ARRAYOFTABLES} = \@tablesRef;
$Input->{SCHEMA} = $table->getMetadata()->getSchema();
$gcons->setInput($Input);
$gcons->run();
my $graph = $gcons->getOutput();

my $kruskal = BMATAN::KKruskal->new();
$kruskal->setInput($graph);
$kruskal->run();
my $UTrees = $kruskal->getOutput();

foreach $UTree (@$UTrees)
  {
    print "The undirected spanning tree is:\n";
    my @edges = @{$UTree->getEdges()};
    foreach $p (@edges)
      {
	print ${@$p}[0],",",${@$p}[1], "\n";
}
}
#my $Tree = $UTree->makeDirected();

#@nodes =  @{$UTree->getNodes()};

#foreach my $n (@nodes)
#{
#    $Tree->addEdge(0,${@$n}[0]);
#}

#print "The directed spanning tree is:\n";
#edges = @{$Tree->getEdges()};
#foreach $p (@edges)
#{
 #   print ${@$p}[0],",",${@$p}[1], "\n";
#}

print "Done\n";
