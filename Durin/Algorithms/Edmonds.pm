# Runs Edmonds algorithm for finding a maximum 
# weighted directed spanning tree in a directed graph.

package Durin::Algorithms::Edmonds;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::DataStructures::WeightedGraph;

sub new_delta {
    my ($class,$self) = @_;
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub run($) {
  my ($self) = @_;
  
  my ($Graph,@sortedEdges,@edges);
  Durin::DataStructures::Graph->new();
  $Graph = $self->getInput()->{GRAPH}->clone();
  my $root = $self->getInput()->{ROOT};
  my $tree = Durin::DataStructures::Graph->new();

  #print "AAAA\n";
  # 1. Discard the arcs entering the root if any; 
  foreach my $parentRoot (@{$Graph->getParents($root)}) {
   # print "BBB\n";
    $Graph->removeEdge($parentRoot,$root);
  }
  # print "CB\n";
  # 2. For each node other than the root, select the entering arc with the smallest cost; Let the selected n-1 arcs be the set S.
  
  foreach my $node (@{$Graph->getNodes()}) {
    if ($node != $root) {
      my ($max,$weigth) = @{$self->findMaxParent($Graph,$node)};
      #print "Node = $node, MaxParent = $max, MaxW = $weigth\n";
      $tree->addEdge($max,$node,$weigth);
    }
  }
  
  #print "Step 2 is over\n";
  
  my @cycles = @{$self->getCycles($tree)};
  
  #print "I have got the cycles\n";
  # 3. If no cycle formed, G(N,S) is a MST. Otherwise, continue.
  while (scalar(@cycles) > 0) {
    # 4. For each cycle formed, contract the nodes in the cycle into a pseudo-node (k), and modify the cost of each arc which enters a node (j) in the cycle from some node (i) outside the cycle according to the following equation.
    # c(i,k)=c(i,j)-(c(x(j),j)-min_{j}(c(x(j),j))
    #where c(x(j),j) is the cost of the arc in the cycle which enters j.
    foreach my $cycle (@cycles) {
      #print "Trying to find the maxParent of the cycle\n";
      my ($maxParent,$maxSon,$weigth) = @{$self->findMaxParentCycle($Graph,$cycle,$tree)};
      #print "I found the maxParent of the cycle\n"; 
      #print "Node = $maxSon, MaxParent = $maxParent, MaxW = $weigth\n";
      # 5. For each pseudo-node, select the entering arc which has the smallest modified cost; Replace the arc which enters the same real node in S by the new selected arc.
      my $actualParent = $tree->getParents($maxSon)->[0];
      $Graph->removeEdge($actualParent,$maxSon);
      $tree->removeEdge($actualParent,$maxSon);
      $tree->addEdge($maxParent,$maxSon,$weigth);
    }
    #print "Tree: ".$tree->makestring();
    #print "Finished processing cycles. One more loop\n";
    @cycles = @{$self->getCycles($tree)};
    # 6. Go to step 3 with the contracted graph.
  }
  $self->setOutput({TREE => $tree});
}
  
#  #@edges = @{$UGraph->getEdges()};
#  my ($p);
#  # foreach $p (@edges)
#  # {
#  # print join(',',@$p),"\n";
#  #   }
#  no strict;
#  #    @sortedEdges = sort { ${@{$b}}[2] <=> ${@{$a}}[2] ;} @edges; 
#  @sortedEdges = sort { $b->[2] <=> $a->[2] ;} @{$UGraph->getEdges()};
#  use strict;
#  # print "And sorted:\n";
#  #foreach $p (@sortedEdges)
#  #{
#  #    print join(',',@$p),"\n";
#  #}
#    my (%nodeSet,@nodes,$nodeRef,$node,$eRef,@e,$UTree,$moving,$n);
#  @nodes = @{$UGraph->getNodes()};
#  foreach $node (@nodes)
#      {
#	$nodeSet{$node} = $node;
#      }
#  $UTree = Durin::DataStructures::UWeightedGraph->new();
#    foreach $eRef (@sortedEdges)
#      {
#	@e = @$eRef;
#	if ($nodeSet{$e[0]} != $nodeSet{$e[1]})
#	  {
#	    $UTree->addEdge($e[0],$e[1],$e[2]);
#	    $moving = $nodeSet{$e[0]};
#	    foreach $n (keys %nodeSet)
#	      {
#		if ($moving == $nodeSet{$n})
#		  {
#		    $nodeSet{$n} = $nodeSet{$e[1]};
#		  }
#	      }		
#	  }
#      }
#    my $output = {};
#    $output->{TREE} = $UTree;
#    $output->{LIST} = \@sortedEdges;
#    $self->setOutput($output);
#}

sub findMaxParent {
  my ($self,$graph,$node) = @_;
  
  my $maxW;
  my $maxParent;
  foreach my $parent (@{$graph->getParents($node)}) {
    my $w = $graph->getEdgeLabel($parent,$node);
    #print "Edge label : $w\n";
    if ((!defined $maxW) || ($w > $maxW)) {
      $maxW = $w;
      $maxParent = $parent;
    }
  }
  return [$maxParent,$maxW];
}

sub findMaxParentCycle {
  my ($self,$Graph,$cycle,$tree) = @_;
  
  my $maxW;
  my $maxParent;
  my $maxSon;
  #print "Before entering the loop with $cycle\n";
  #print join(",",@$cycle)."\n";
  foreach my $cycleNode (keys %$cycle) {
    #print "Looking for possibilities to substitute $cycleNode parent\n";
    my $actualParent = $tree->getParents($cycleNode)->[0];
    my $actualWeigth = $tree->getEdgeLabel($actualParent,$cycleNode);
    foreach my $alternativeParent (@{$Graph->getParents($cycleNode)}) {
      if (!$cycle->{$alternativeParent}) {
	#print "concretely with $alternativeParent\n";
	my $alternativeWeigth = $Graph->getEdgeLabel($alternativeParent,$cycleNode);
	my $w = $alternativeWeigth - $actualWeigth;
	if ((!defined $maxW) || ($maxW < $w)) {
	  $maxW = $w;
	  $maxParent = $alternativeParent;
	  $maxSon = $cycleNode;
	}
      }
    }
  }
  return [$maxParent,$maxSon,$maxW];
}

sub getCycles {
  my ($self,$tree) = @_;
  
  my $cycles = [];
  my $visited = {};
  foreach my $node (@{$tree->getNodes()}) {
    if (!$visited->{$node}) {
      my $thisNodeVisited = {};
      $thisNodeVisited->{$node} = 1;
      my $cycleFound = 0;
      my $actualNode = $node;
      my $parents = $tree->getParents($actualNode);
      while (!$cycleFound && (scalar(@$parents) > 0)) {
	$actualNode = $parents->[0];
	if ($visited->{$actualNode}) {
	  $cycleFound = 1;
	}
	if ($thisNodeVisited->{$actualNode}) {
	  # We have found a cycle that contains $actualNode.
	  my $cycle = $self->constructCycle($tree,$actualNode);
	  push @$cycles,$cycle;
	  $cycleFound = 1;
	}
	$visited->{$actualNode} = 1;
	$thisNodeVisited->{$actualNode} = 1;
	$parents = $tree->getParents($actualNode);
      }
    }
  }
  return $cycles;
}

# Given a graph wich a cycle that comprises $node enumerates 
# the nodes in the cycle.

sub constructCycle {
  my ($self,$tree,$node) = @_;
  
  my $nodeHash = {};
  my $actualNode = $node;
  #print "Creating a cycle\n"; 
  
  do {
    $nodeHash->{$actualNode} = 1;
    #print "AddingNode $actualNode\n";
    $actualNode = $tree->getParents($actualNode)->[0];
  } while ($actualNode != $node);
  return $nodeHash;
}
1;
