package Durin::NB::NB;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

sub new_delta
{
  my ($class,$self) = @_;
  
  #$self->{COUNTTABLE} = undef; 
  $self->{PROBAPPROX} = undef;
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::NB::NB clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
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

sub predict
  {
    my ($self,$row_to_classify) = @_;;
    
    my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob,@nodes,$node,@parents,$parent,$parent_val,$CXYClass,$PUpgrade,$tree,$node_val);
    
    #my $ct = $self->{COUNTTABLE};
    my $PA = $self->{PROBAPPROX};
    
    $schema = $self->getSchema();
    $class_attno = $schema->getClassPos();
    $class_att = $schema->getAttributeByPos($class_attno);
    @class_values = @{$class_att->getType()->getValues()};
    
    foreach $class_val (@class_values)
      {
	$Prob{$class_val} = $PA->getPClass($class_val);
	#print "A priori Prob{$class_val} = ",$Prob{$class_val},"\n";
	  #($ct->getCountClass($class_val) + 1)/($ct->getCount() + $#class_values + 1) ;
      }
    
    for ($node = 0 ; $node < $schema->getNumAttributes() ; $node++)
      {
	if ($node != $class_attno)
	  {	
	    $node_val = $row_to_classify->[$node];
	    #my $card = $schema->getAttributeByPos($node)->getType()->getCardinality();
	    foreach $class_val (@class_values)
	      {
		$PUpgrade = $PA->getPXCondClass($class_val,$node,$node_val);
		#print "Factor $node=$node_val: $PUpgrade\n";
		#($ct->getCountXClass($class_val,$node,$node_val) + 1) / ($ct->getCountClass($class_val) + $card);  
		$Prob{$class_val} = $Prob{$class_val} * $PUpgrade;
	      }
	  }
      }
    
    my $sum = 0.0; 
    my $max;
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
	    #print "Prob{$class_val} = ",$Prob{$class_val},"\n";
	  }
      }
    else
      {
	foreach $class_val (@class_values)
	  {
	    $Prob{$class_val} = 1 / ($#class_values + 1); 
	  }
      }
    #print "Class: $max\n";
    return ([\%Prob,$max]);
  }

sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

#sub classify
#  {
#    my ($self,$row_to_classify) = @_;
#    
#    my (@ct,$ct->getCount(),%countClass,%countXClass,%countXYClass);
#    
#    @ct = @{$self->getCountTable()};
#    $ct->getCount() = $ct[0];
#    $ct->getCount() = $$ct->getCount();
#    #    print "Count $ct->getCount()\n";
#    %countClass = %{$ct[1]};
#    %countXClass = %{$ct[2]};
#    
#    my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob,@nodes,$node,@parents,$parent,$parent_val,$CXYClass,$PUpgrade,$tree,$node_val);
#    
#    $schema = $self->getSchema();
#    $class_attno = $schema->getClassPos();
#    $class_att = $schema->getAttributeByPos($class_attno);
#    @class_values = @{$class_att->getType()->getValues()};
#    #print @class_values,"\n";
#    #print join(',',@class_values),"\n";
#    foreach $class_val (@class_values)
#      {
#	#print "Class = $class_val, cv[0] = ",$class_values[0]," \n";
#	#print $ct->getCountClass({$class_val},"\n";
#	$Prob{$class_val} = ($ct->getCountClass({$class_val} + 1)/($ct->getCount() + $#class_values) ;
#      }
#    
#    for ($node = 0 ; $node < $schema->getNumAttributes() ; $node++)
#      {
#	if ($node != $class_attno)
#	  {	
#	      $node_val = $row_to_classify->[$node];
#	      my $card = $schema->getAttributeByPos($node)->getType()->getCardinality();
#	      foreach $class_val (@class_values)
#	      {
#		  # print "$class_val , $node, $node_val \n";
#		  $PUpgrade = ($ct->getCountXClass($class_val}[$node]{$node_val} + 1) / ($ct->getCountClass({$class_val} + $card);  
#		  $Prob{$class_val} = $Prob{$class_val} * $PUpgrade;
#	      }
#	  }
#      }
#    
#    
#    my ($Max,$ProbMax);
#    $Max = 0;
#    $ProbMax = 0;
#    foreach $class_val (@class_values)
#      {
#	if ($ProbMax < $Prob{$class_val})
#	  {
#	    $ProbMax = $Prob{$class_val};
#	    $Max = $class_val;
#	  }
#      }
#    return $Max;
#  }

