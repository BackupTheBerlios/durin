use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1};

use Durin::Algorithms::Kruskal;
use Durin::DataStructures::UGraph;
use IO::File;

my $file = new IO::File ("<t/KruskalTestResult");
my $expectedResult = join("",$file->getlines());

my $G = Durin::DataStructures::UGraph->new();

$G->addEdge(1,2,3);
$G->addEdge(2,3,4);
$G->addEdge(1,3,4);
$G->addEdge(1,4,5);
$G->addEdge(3,4,5);

my $Kruskal = Durin::Algorithms::Kruskal->new();

{
  my $input = {};
  $input->{GRAPH} = $G;
  $Kruskal->setInput($input);
}

$Kruskal->run();

my $tree = $Kruskal->getOutput()->{TREE}->makeDirected();
my $realResult = "";
foreach my $edge (@{$tree->getEdges()})
  {
    $realResult .= join(",",@$edge)."\n";
  }
$realResult .= "Done\n";
ok($realResult,$expectedResult);
