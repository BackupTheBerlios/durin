use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1};

use Durin::Algorithms::Edmonds;
use Durin::DataStructures::Graph;
use IO::File;

#my $file = new IO::File ("<t/Edmonds	TestResult");
#my $expectedResult = join("",$file->getlines());

my $G = Durin::DataStructures::Graph->new();

$G->addEdge(1,2,0);
$G->addEdge(1,3,0);
$G->addEdge(1,4,0);
$G->addEdge(2,4,2);
$G->addEdge(4,2,3);
$G->addEdge(4,3,3);
$G->addEdge(3,2,1);

print "Graph constructed\n";
foreach my $edge (@{$G->getEdges()}) {
    print join(",",@$edge)."\n";
  }	

my $G2 = $G->clone();
print "Graph cloned\n";
foreach my $edge (@{$G2->getEdges()})
  {
     print join(",",@$edge)."\n";
  }

my $edmonds = Durin::Algorithms::Edmonds->new();

{
  my $input = {};
  $input->{GRAPH} = $G;
  $input->{ROOT} = 1;
  $edmonds->setInput($input);
}

$edmonds->run();

my $tree = $edmonds->getOutput()->{TREE};
my $realResult = "";
foreach my $edge (@{$tree->getEdges()})
  {
    print join(",",@$edge)."\n";
  }
$realResult .= "Done\n";
#ok($realResult,$expectedResult);
