# Implements a undirected graph. 
# BUGS: Relabeling a node does not work!!

package Durin::DataStructures::WeightedGraph;

use Durin::DataStructures::Graph;

@ISA = (Durin::DataStructures::Graph);

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{TOTALWEIGHT} = 0;
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_; 
  }

sub addEdge
  {
    my ($self,$e1,$e2,$label) = @_;
    
    #print "Adding edge $e1,$e2,$label\n";
    if ($self->areConnected($e1,$e2))
      {
	# Caution!!! this is not yet implemented!!!!
	die "WeightedGraph::addEdge NYI\n";
      }
    else
      {
	$self->{TOTALWEIGHT} += $label;
      }
    $self->SUPER::addEdge($e1,$e2,$label);
  }

sub getWeight
  {
    my ($self) = @_;
    
    return $self->{TOTALWEIGHT};
  }

1;
