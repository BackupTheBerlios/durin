# Implements a directed graph

package Durin::DataStructures::Graph;

use strict;
use warnings;

use Durin::Basic::MIManager;

@Durin::DataStructures::Graph::ISA = qw(Durin::Basic::MIManager);

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{NODES} = {};
    $self->{NODELIST} = [];
    $self->{EDGES} = {};
    $self->{INVERTEDEDGES} = {};
    $self->{EDGELIST} = [];
    
#self->{PARENTSHASH} = {};
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    my (@edgeList,$e);
    @edgeList = @{$source->getEdges()};
    foreach $e (@edgeList)
    {
	$self->addEdge($e->[0],$e->[1],$e->[2]);
    }
#   print "DataStructures::UGraph cloning not tested\n");
}

sub addEdge($$$$)
{
  my ($self,$parent,$son,$label) = @_;
  
  if (!exists $self->{NODES}{$parent})
    {
      $self->{NODES}{$parent} = undef;
      push @{$self->{NODELIST}},($parent);
    }
  if (!exists $self->{NODES}{$son})
    {
      $self->{NODES}{$son} = undef;
      push @{$self->{NODELIST}},($son);
    }
  
  $self->{EDGES}{$parent}{$son} = $label;
  $self->{INVERTEDEDGES}{$son}{$parent} = $label;
  push @{$self->{EDGELIST}},([$parent,$son,$label]); 
# push @{$self->{PARENTSHASH}->{
}

sub removeEdge($$$) {
  my ($self,$parent,$son) = @_;
  
  delete $self->{EDGES}{$parent}{$son};
  delete $self->{INVERTEDEDGES}{$son}{$parent};
  my $edgePos = $self->findEdgePos($parent,$son);
  #print "Prior to removing edge $parent->$son\n**********************\n";	
  #foreach my $edge (@{$self->getEdges()}) {
  #3  print join(",",@$edge)."\n";
  #}
  splice (@{$self->{EDGELIST}},$edgePos,1);
  #print "After removing edge $parent->$son\n**********************\n";
  #foreach my $edge (@{$self->getEdges()}) {
  #  print join(",",@$edge)."\n";
  #}
}
	
sub findEdgePos($$$) {
  my ($self,$parent,$son) = @_;
  
  my $i = 0;
  my $edgeList = $self->{EDGELIST};
  my $found = 0;
  while (($i < scalar(@$edgeList)) && (!$found)) {
    my $edge = $edgeList->[$i];
    $found = (($edge->[0] == $parent) && ($edge->[1] == $son));
    if (!$found) {
      $i++;
    }
  }
  return $i;
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
  
  if (exists $self->{EDGES}{$e1}{$e2})
    {
      return $self->{EDGES}{$e1}{$e2};
    }
  else
    {
      return undef;
    }
}

sub areConnected
  {
    my ($self,$e1,$e2) = @_;
    
    if (exists $self->{EDGES}{$e1}{$e2})
      {	
	#print $e1,",",$e2," are connected\n";
	return 1;
      }
    else
      {
	return 0;
      }
  }

sub getEdges($)
{
    my ($self) = @_;
    return $self->{EDGELIST};
}

sub getNodes
  {
    my ($self) = @_;
    return $self->{NODELIST};
  }   

sub getParents
  {
    my ($self,$son) = @_;
    
    my @list = keys %{$self->{INVERTEDEDGES}{$son}};
    return \@list;
  }

sub getSons
  {
    my ($self,$parent) = @_;
    
    my @list = keys %{$self->{EDGES}{$parent}};
    return \@list;
  }

sub getAncestors
  {
    my ($self,$x) = @_;
   
    my %set;
    my $left = [$x];
    while (scalar(@$left) > 0)
      {
	my $this = shift @$left;
	my $parents = $self->getParents($this);
	foreach my $p (@$parents)
	  {
	    if (!exists $set{$p})
	      {
		$set{$p} = 1;
		push @$left,($p);
	      }
	  }
      }
    my @k = keys %set;
    #print "Ancestors of $x:",join(",",@k),"\n";
    return \%set;
  }

sub isAncestor
  {
    my ($self,$ancestor,$x) = @_;
    
    return (exists $self->getAncestors($x)->{$ancestor});
  }

# Finds the root node given a node in a directed graph

sub getRootByNode {
  my ($self,$node) = @_;

  my $nodeParents = $self->getParents($node);
  while (scalar @$nodeParents) {
    #print "$node\n";
    $node = $nodeParents->[0];
    $nodeParents = $self->getParents($node);
  }
  return $node;
}

sub getRoot {
  my ($self) = @_;
  
  return ($self->getRootByNode($self->{NODELIST}[0]));
}

sub makestring {
  my ($self) = @_;
  
  my $str = "";
  foreach my $e (@{$self->{EDGELIST}}) {
    if (defined $e->[2]) {
      $str .= $e->[0]."-".$e->[1]." w=".$e->[2]."\n";
    } else {
      $str .= $e->[0]."-".$e->[1]."\n";
    }
  }
  return $str;
}
