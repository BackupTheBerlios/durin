use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1};

use Durin::Algorithms::Gabow;
use Durin::DataStructures::UGraph;
use IO::File;

my $file = new IO::File ("<t/GabowTestResult");
my $expectedResult = join("",$file->getlines());

#print $expectedResult;

my $G = Durin::DataStructures::UGraph->new();

$G->addEdge(1,2,3);
$G->addEdge(2,3,4);
$G->addEdge(1,3,4);
$G->addEdge(1,4,5);
$G->addEdge(3,4,5);
$G->addEdge(4,2,1);

my $Gabow = Durin::Algorithms::Gabow->new();

{
  my $input = {};
  $input->{GRAPH} = $G;
  $input->{K} = 20;
  $Gabow->setInput($input);
}

$Gabow->run();

my $output = $Gabow->getOutput();
my @L = @{$output->{TREELIST}};
my $realResult = "";
foreach my $Tree (@L)
  {
    $realResult .= "*** Tree with weight: ".$Tree->getWeight()."\n";
    foreach my $edge (@{$Tree->getEdges()})
      {
	$realResult .= "[$edge->[0],$edge->[1],$edge->[2]]\n";
      }
  }
#print $realResult;
ok($realResult,$expectedResult);