#CARE!!!!! PROBABLY OBSOLETE

# Runs Kruskal for finding a k maximum weighted spanning tree

package Durin::BMATAN::FirstMTreeGen;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::DataStructures::UGraph;

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

sub run
{
    my ($self) = @_;
    
    my ($UGraph,@sortedEdges,@edges);
    
    $UGraph = $self->getInput()->{GRAPH};
    
    @edges = @{$UGraph->getEdges()};
    my ($p);
    # foreach $p (@edges)
    # {
    # print join(',',@$p),"\n";
    #   }
    no strict;
    # @sortedEdges = sort { ${@{$b}}[2] <=> ${@{$a}}[2] ;} @edges;
    @sortedEdges = sort { $b->[2] <=> $a->[2] ;} @edges;
    use strict;
    #print "And sorted:\n";
    #foreach $p (@sortedEdges)
    #{
    #    print join(',',@$p),"\n";
    #}
    
    my @nodes = @{$UGraph->getNodes()};
    my $pair = makeTree(\@sortedEdges,\@nodes);
    my $UTree = $pair->[0];
    my @edgeIndexes = @{$pair->[1]};
    my @UTrees = ($UTree);

    # We generate some more trees by deleting an edge at a time
    
    #print "Original:\n";
    #foreach my $edge (@sortedEdges)
#  {  
#    print "[",$edge->[0],",",$edge->[1],"],";
#  }
#print "\n";
    my (@sortedEdgeIndexes,$edgeToDeleteIndex,$i,$deletedEdge);

    @sortedEdgeIndexes = sort{ $a->[1] <=> $b->[1]; } @edgeIndexes;
    $i = 0;
    
    foreach my $edgeRef (@sortedEdgeIndexes)
    {
	$edgeToDeleteIndex = $edgeRef->[0];
	$deletedEdge = $sortedEdges[$edgeToDeleteIndex];
	#print "Edge deleted: ",$deletedEdge->[0],",",$deletedEdge->[1],"\n";
	splice(@sortedEdges,$edgeToDeleteIndex,1);
	#    print "After deletion:\n";
	#    foreach my $edge (@sortedEdges)
	#      {  
	#	print "[",$edge->[0],",",$edge->[1],"],";
	#      }
	#    print "\n";
	my $newUTree = makeTree(\@sortedEdges,\@nodes)->[0];
	#foreach my $edge (@{$newUTree->getEdges()})
	#  {
	#    print "[",$edge->[0],",",$edge->[1],"],";
	#  }
	splice(@sortedEdges,$edgeToDeleteIndex,0,$deletedEdge);
	#    print "After reinsertion:\n";
	#    foreach my $edge (@sortedEdges)
	#      {  
	#	print "[",$edge->[0],",",$edge->[1],"],";
	#      }
	#    print "\n";
	$i++;
	$UTrees[$i] = $newUTree; 
	last if ($i > 8)
    }
    my $output = {};
    $output->{TREELIST} = \@UTrees;
    $self->setOutput($output);
}


sub makeTree
  {
    my ($refEdges,$refNodes) = @_;
    
    my (%nodeSet,@nodes,$nodeRef,$node,$eRef,@e,$UTree,$moving,$n,@sortedEdges);
    @nodes = @$refNodes;
    @sortedEdges = @$refEdges;
    
    foreach $node (@nodes)
      {
	$nodeSet{$node} = $node;
      }
    $UTree = Durin::DataStructures::UWeightedGraph->new();
    my ($i,@EdgesToDelete);
    $i= 0;
    @EdgesToDelete = ();
    foreach $eRef (@sortedEdges)
      {
	@e = @$eRef;
	if ($nodeSet{$e[0]} != $nodeSet{$e[1]})
	  {
	    push @EdgesToDelete,([$i,$e[2]]);
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
	$i++;
      }
    my $WeightedTree = Durin::DataStructures::WeightedGraph->new();
    $UTree->copyDirectedTo($WeightedTree);
    return [$WeightedTree,\@EdgesToDelete];
  }
1;
