# Implements a undirected TAN 
# (the optimal TAN coming from a decomposable over TANS).

package Durin::TAN::UTAN;

use strict;
use warnings;

use base 'Durin::Classification::Model';

use Class::MethodMaker
  get_set => [ -java => qw/Tree DecomposableDistribution/];

use Durin::Data::MemoryTable;


sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setTree(undef);
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::TAN::TAN clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
}

sub predict
{
    my ($self,$row_to_classify) = @_;
    
    my (@ct,$count,%countClass,%countXClass,%countXYClass);
    
    my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob,@nodes,$node,@parents,$parent,$parent_val,$CXYClass,$PUpgrade,$node_val);
    
    $schema = $self->getSchema();
    $class_attno = $schema->getClassPos();
    $class_att = $schema->getAttributeByPos($class_attno);
    @class_values = @{$class_att->getType()->getValues()};
    
    my $distrib = $self->getDecomposableDistribution();

    # Initialize the probabilities so that every class is equally probable

    foreach $class_val (@class_values) {
      $Prob{$class_val} = 1;
    }

    # Calculate all the h0's and update the class probabilities
    
    for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
      if ($node_u != $class_attno) {
	my $u_val = $row_to_classify->[$node_u];
	foreach $class_val (@class_values) {
	  my $PUpdate = $distrib->getNQuoteAsteriscUC($class_val,$node_u,$u_val);
	  $Prob{$class_val} *= $PUpdate;
	}
      }
    }

    # Calculate all the h_u,v and update the class probabilities
    my $tree = $self->getTree();
    foreach my $edge (@{$tree->getEdges()}) {
      my $node_u = $edge->[0];
      my $node_v = $edge->[1];
      my $u_val = $row_to_classify->[$node_u];
      my $v_val = $row_to_classify->[$node_v];
      foreach $class_val (@class_values) {
	my $PUpdate = $distrib->huv($class_val,$node_u,$u_val,$node_v,$v_val);
	$Prob{$class_val} *= $PUpdate;
      }
    }
    
    # Normalization of probabilities & calculation of the most probable class
    
    my $sum = 0.0; 
    my $max = 0;
    my $probMax = 0.0;
    foreach $class_val (@class_values)
      {
	if ($probMax <= $Prob{$class_val})
	  {
	    $probMax = $Prob{$class_val};
	    $max = $class_val;
	  }
	$sum += $Prob{$class_val}; 
      }
    my %condProb;
    if ($sum != 0)
      {
	foreach $class_val (@class_values)
	  {
	    $condProb{$class_val} = ($Prob{$class_val} / $sum); 
	  }
      }
    else
      {
	foreach $class_val (@class_values)
	  {
	    $condProb{$class_val} = 1 / ($#class_values + 1); 
	  }
      }
    #foreach $class_val (@class_values)
    #  {
    #	print "P($class_val) = ",$Prob{$class_val},","; 
    #      }
    #print "\n";
    return ([\%condProb,$max,\%Prob,$sum]);
}

sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

#sub h0update {
#  my ($distrib,$class_val,$node_u,$u_val) = @_;
  
#  return $distrib->getNQuoteUC($node_u,$u_val,$class_val);
#}



1;
