# Implements a undirected TAN 
# (the optimal TAN coming from a decomposable over TANS).

package Durin::TAN::UTAN;

use strict;
use warnings;

use base 'Durin::Classification::Model';

use Durin::Data::MemoryTable;


sub new_delta
{
  my ($class,$self) = @_;
  
  $self->{TREE} = undef;
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::TAN::TAN clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
}

sub setTree
  {
    my ($self,$tree) = @_;
    
    $self->{TREE} = $tree;
  }

sub getTree
  {
    my ($self) = @_;
    
    return $self->{TREE};
  }

sub setProbApprox
  {
    my ($self,$PA) = @_;
    
    $self->{PROBAPPROX} = $PA;
  }

sub getProbApprox
  {
    my ($self) = @_;
    
    return $self->{PROBAPPROX};
  }

sub predict
{
    my ($self,$row_to_classify) = @_;
    
    my (@ct,$count,%countClass,%countXClass,%countXYClass);
    
    my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob,@nodes,$node,@parents,$parent,$parent_val,$CXYClass,$PUpgrade,$tree,$node_val);
    
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
	  my $PUpdate = $self->h0update($distrib,$class_val,$node_u,$u_val);
	  $Prob{$class_val} *= $PUpdate;
	}
      }
    }

    # Calculate all the h_u,v and update the class probabilities
    
    foreach my $edge (@{$tree->getEdges()}) {
      my $node_u = $edge->[0];
      my $node_v = $edge->[1];
      my $u_val = $row_to_classify->[$node_u];
      my $v_val = $row_to_classify->[$node_u];
      foreach $class_val (@class_values) {
	my $PUpdate = $self->huv($distrib,$class_val,$node_u,$u_val,$node_v,$u_val);
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

sub h0update {
  my ($distrib,$class_val,$node_u,$u_val) = @_;
  
  return $distrib->getNQuoteUC($node_u,$u_val,$class_val);
}

sub huv {
  my ($distrib,$class_val,$node_u,$u_val,$node_v,$v_val) = @_;

  my $num = $distrib->getNQuoteUVC($node_u,$u_val,$node_v,$v_val,$class_val);
  my $denom  = $distrib->getNQuoteUC($node_u,$u_val,$class_val) * 
    $distrib->getNQuoteUC($node_v,$v_val,$class_val);
  return $num / $denom;
}

#sub generateDataset {
#    my ($self,$numRows)  = @_;

#    my $dataset = Durin::Data::MemoryTable->new();
#    my $metadataDataset = Durin::Metadata::Table->new();
#    $metadataDataset->setSchema($self->getSchema());
#    $metadataDataset->setName("tmp");
#    $dataset->setMetadata($metadataDataset);

#    my $count = 0;
#    $dataset->open();
#    for my $i (1..$numRows) {
#      my $row = $self->generateObservation();
#      #print join(",",@$row)."\n";
#      $dataset->addRow($row);
#    }
#    $dataset->close();
#    return $dataset;
#  }

sub generateObservation {
  my ($self) = @_;

  my $row = [];

  # Generate class

  my $classPos = $self->getSchema()->getClassPos();
  my $classVal = $self->{PROBAPPROX}->sampleClass();
  $row->[$classPos] = $classVal;

  # Recursively generate attribute values from the root downwards
  my $tree = $self->getTree();
  my $root = $tree->getRoot();

  $self->recursivelyGenerateValues($row,$root);
  #print "\n";
  print ".";

  return $row;
}

sub recursivelyGenerateValues {
  my ($self,$row,$node) = @_;

  my $classPos = $self->getSchema()->getClassPos();
  my $classVal = $row->[$classPos];
  my $tree = $self->getTree();
  my $parents = $tree->getParents($node);
  my $numParents = scalar @$parents;
  if ($numParents == 0) {
    # Root
    #print "$node-r";
    my $nodeVal = $self->{PROBAPPROX}->sampleXCondClass($classVal,$node);
    $row->[$node] = $nodeVal;
  } else {
    #print "-$node";
    my $parent = $parents->[0];
    my $parentVal = $row->[$parent];
    my $nodeVal = $self->{PROBAPPROX}->sampleYCondXClass($classVal,$parent,$parentVal,$node);
    $row->[$node] = $nodeVal;
  }
  my $sons = $tree->getSons($node);
  foreach my $son (@$sons) {
    $self->recursivelyGenerateValues($row,$son);
  }
}
