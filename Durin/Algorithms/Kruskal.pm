# Runs Kruskal for finding a maximum weighted spanning tree

package Durin::Algorithms::Kruskal;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::DataStructures::UWeightedGraph;

sub new_delta
  {
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
    my ($self) = @_;
    
    my ($UGraph,@sortedEdges,@edges);
    
    $UGraph = $self->getInput()->{GRAPH};
    
    #@edges = @{$UGraph->getEdges()};
    my ($p);
    # foreach $p (@edges)
    # {
    # print join(',',@$p),"\n";
    #   }
    no strict;
    #    @sortedEdges = sort { ${@{$b}}[2] <=> ${@{$a}}[2] ;} @edges; 
    @sortedEdges = sort { $b->[2] <=> $a->[2] ;} @{$UGraph->getEdges()};
    use strict;
    # print "And sorted:\n";
    #foreach $p (@sortedEdges)
    #{
    #    print join(',',@$p),"\n";
    #}
    my (%nodeSet,@nodes,$nodeRef,$node,$eRef,@e,$UTree,$moving,$n);
    @nodes = @{$UGraph->getNodes()};
    foreach $node (@nodes)
      {
	$nodeSet{$node} = $node;
      }
    $UTree = Durin::DataStructures::UWeightedGraph->new();
    foreach $eRef (@sortedEdges)
      {
	@e = @$eRef;
	if ($nodeSet{$e[0]} != $nodeSet{$e[1]})
	  {
	    $UTree->addEdge($e[0],$e[1],$e[2]);
	    $moving = $nodeSet{$e[0]};
	    foreach $n (keys %nodeSet)
	      {
		if ($moving == $nodeSet{$n})
		  {
		    $nodeSet{$n} = $nodeSet{$e[1]};
		  }
	      }		
	  }
      }
    my $output = {};
    $output->{TREE} = $UTree;
    $output->{LIST} = \@sortedEdges;
    $self->setOutput($output);
  }

1;
