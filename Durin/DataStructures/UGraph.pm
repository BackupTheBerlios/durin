# Implements a undirected graph. 
# BUGS: Relabeling a node does not work!!


package Durin::DataStructures::UGraph;

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

use strict;
use Durin::DataStructures::Graph;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{NODES} = {};
    $self->{NODELIST} = [];
    $self->{EDGES} = {};
    $self->{EDGELIST} = [];
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    my (@edgeList,$e);
    
    @edgeList = $source->getEdges();
    foreach $e (@edgeList)
    {
	$self->addEdge($e);
    }
#    print "DataStructures::UGraph cloning not tested\n");
}

sub addEdge
  {
    my ($self,$e1,$e2,$label) = @_;
    
    if (!exists $self->{NODES}{$e1})
    {
      $self->{NODES}{$e1} = undef;
      push @{$self->{NODELIST}},($e1);
    }
    if (!exists $self->{NODES}{$e2})
      {
	$self->{NODES}{$e2} = undef;
 	push @{$self->{NODELIST}},($e2);
      }
    
    if (exists $self->{EDGES}{$e2}{$e1})
      {
	# Caution!!! this is not yet implemented!!!!
	die "UGraph::adEdge NYI\n";
	$self->{EDGES}{$e2}{$e1} = $label;
	push @{$self->{EDGELIST}},([$e2,$e1,$label]); 
      }
    else
      {
	$self->{EDGES}{$e1}{$e2} = $label;
	push @{$self->{EDGELIST}},([$e1,$e2,$label]); 
      }
  }

sub addNode($$$)
{
    my ($self,$node,$label) = @_;
    
    $self->{NODES}{$node} = $label;
    push @{$self->{NODELIST}},($node);
}

sub getNodeLabel($$)
{
    my ($self,$node,$label) = @_;
    
    if (exists $self->{NODES}{$node})
    {
	return $self->{NODES}{$node};
    }
    else
    {
	return undef;
    }
}

sub getEdgeLabel($)
{
    my ($self,$e1,$e2) = @_;
     
   if (exists $self->{EDGES}{$e2}{$e1})
    {
	return $self->{EDGES}{$e2}{$e1};
    }
    else
    {
	if (exists $self->{EDGES}{$e1}{$e2})
	{
	    return $self->{EDGES}{$e1}{$e2};
	}
	else
	{
	    return undef;
	}
    }
}

sub areConnected($$)
{
    my ($self,$e1,$e2) = @_;
    
    if (exists $self->{EDGES}{$e2}{$e1})
    {
	return 1;
    }
    else
    {
	if (exists $self->{EDGES}{$e1}{$e2})
	{
	    return 1;
	}
	else
	  {
	    return 0;
	}
    }
}

sub getEdges($)
{
    my ($self) = @_;
    return $self->{EDGELIST};
}

sub getNodes($)
{
    my ($self) = @_;
    return $self->{NODELIST};
}   

sub copyDirectedTo
  {
    my ($self,$Tree) = @_;
    
    my @rest = ();
    my @heap = ();
    my %notConsidered;
    my @nodes =  @{$self->getNodes()};
    foreach my $n (@nodes)
      {
	$notConsidered{$n} = undef;
      }
    @rest = keys %notConsidered;
    my $n1 = pop @rest;
    delete $notConsidered{$n1};
    #print join(',',@rest),"\n";
    while ($#rest != -1)
      {
	#print "Processing $n1 ",join(',',@rest),"\n";
	foreach my $n2 (@rest)
	  {
	    if ($self->areConnected($n1,$n2))
	      {
		$Tree->addEdge($n1,$n2,$self->getEdgeLabel($n1,$n2));
		delete $notConsidered{$n2};
		push @heap,($n2);
		
	      }
	  }
	$n1 = pop @heap;
	@rest = keys %notConsidered;
	#print join(',',@rest)," length: ",$#rest,"\n";
      }   
    return $Tree;
  }

sub makeDirected
  {
    my ($self) = @_;
    
    my $Tree = Durin::DataStructures::Graph->new();
    
    return $self->copyDirectedTo($Tree);
  }

1;
