package Durin::TAN::TAN;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

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
    #    print join(",",@nodes),"\n";
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
		$PUpgrade = $PA->getPYCondXClass($class_val,$parent,$parent_val,$node,$node_val);
		$Prob{$class_val} = $Prob{$class_val} * $PUpgrade;
	      }
	  }
	else
	  {
	    foreach $class_val (@class_values)
	      {
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
    if ($sum != 0)
      {
	foreach $class_val (@class_values)
	  {
	    $Prob{$class_val} = ($Prob{$class_val} / $sum); 
	  }
      }
    else
      {
	foreach $class_val (@class_values)
	  {
	    $Prob{$class_val} = 1 / ($#class_values + 1); 
	  }
      }
    #foreach $class_val (@class_values)
    #  {
    #	print "P($class_val) = ",$Prob{$class_val},","; 
    #      }
    #print "\n";
    return ([\%Prob,$max]);
}

sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }
