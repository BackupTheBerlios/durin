package Durin::TAN::TAN;

use strict;
use warnings;

use Durin::Classification::Model;

@Durin::TAN::TAN::ISA =  qw(Durin::Classification::Model);

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

#sub setCountTable
#{
#    my ($self,$ct) = @_;
#    
#    $self->{COUNTTABLE} = $ct;
#}

#sub getCountTable
#{
#    my ($self) = @_;
#    
#    return $self->{COUNTTABLE};
#}

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
    
    #   @ct = @{$self->getCountTable()};
    #   $count = $ct[0];
    #   $count = $$count;
    # print "Count $count\n";
    #   %countClass = %{$ct[1]};
    #   %countXClass = %{$ct[2]};
    #   %countXYClass = %{$ct[3]};
    
    my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob,@nodes,$node,@parents,$parent,$parent_val,$CXYClass,$PUpgrade,$tree,$node_val);
    
    $schema = $self->getSchema();
    $class_attno = $schema->getClassPos();
    $class_att = $schema->getAttributeByPos($class_attno);
    @class_values = @{$class_att->getType()->getValues()};
    #print @class_values,"\n";
    #print join(',',@class_values),"\n";

    my $PA = $self->getProbApprox();

    foreach $class_val (@class_values)
      {
	#print "Class = $class_val, cv[0] = ",$class_values[0]," \n";
	#print $countClass{$class_val},"\n";
	$Prob{$class_val} = $PA->getPClass($class_val);
	
	#      ($countClass{$class_val} + 1)/($count + $#class_values + 1) ;
      }
    $tree = $self->getTree();
    @nodes = @{$tree->getNodes()};
    #print join(",",@nodes),"\n";
    foreach my $node (@nodes)
      {	
	$node_val = $row_to_classify->[$node];
	my ($parentsRef);
	$parentsRef = $tree->getParents($node);
	@parents = @$parentsRef;
	#my $card =  $schema->getAttributeByPos($node)->getType()->getCardinality();
	#print "Number of parents of $node: ",$#parents+1,"\n";
	if ($#parents+1 == 1)
	  {
	    $parent = $parents[0];
	    $parent_val = $row_to_classify->[$parent];
	    #print "Parent: $parent\n";
	    foreach $class_val (@class_values)
	      {
		#print "Asking PATAN for $class_val,$parent,$parent_val,$node,$node_val\n";
		$PUpgrade = $PA->getPYCondXClass($class_val,$parent,$parent_val,$node,$node_val);
		$Prob{$class_val} = $Prob{$class_val} * $PUpgrade;
	      }
	  }
	else
	  {
	    foreach $class_val (@class_values)
	      {	
		#print "Asking PATAN for $class_val,$node,$node_val\n";
		$PUpgrade = $PA->getPXCondClass($class_val,$node,$node_val);
		  
		#$PUpgrade = ($countXClass{$class_val}[$node]{$node_val} + 1) / ($countClass{$class_val} + $card);  
		$Prob{$class_val} = $Prob{$class_val} * $PUpgrade;
		#if ($PUpgrade == 0)
		#  {
		#    print "Mamon $node,$node_val\n";
		#  }
	      }
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
