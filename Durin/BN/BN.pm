package Durin::BN::BN;

use strict;
use warnings;

use base 'Durin::Classification::Model';
use Class::MethodMaker get_set => [-java => qw/ Graph CPTHash ParentsHash/];

#use Durin::Data::MemoryTable;
use Durin::Math::Prob::Multinomial;
use Durin::DataStructures::Graph;

sub new_delta {
  my ($class,$self) = @_;
  
  $self->setGraph(Durin::DataStructures::Graph->new());
  $self->setCPTHash({});
  $self->setParentsHash({});
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
  
  die "Durin::BN::BN clone not implemented";
  #   $self->setMetadata($source->getMetadata()->clone());
}

sub addEdge {
  my ($self,$parent,$son) = @_;
  
  $self->getGraph()->addEdge($parent,$son);
  # Keep parents in order
  if (!exists $self->getParentsHash()->{$son}) {
    $self->getParentsHash()->{$son} = [];
  }
  push @{$self->getParentsHash()->{$son}},$parent;
}

sub getParents {
  my ($self,$node) = @_;

  return $self->getParentsHash()->{$node};
}

sub addCPT {
  my ($self,$node,$parentConfiguration,$conditionalProbabilityTable) = @_;
  
  if (!exists $self->getCPTHash()->{$node}) {
    $self->getCPTHash()->{$node} = {};
  }
  my $CPTHash = $self->getCPTHash()->{$node};
  
  foreach my $parentValue (@$parentConfiguration) {
    if (!exists $CPTHash->{$parentValue}) {
      $CPTHash->{$parentValue} = {};
    }
    $CPTHash = $CPTHash->{$parentValue};
  }
  my $multinomial = Durin::Math::Prob::Multinomial->new();
  $multinomial->setDimensions(1);
  $multinomial->setCardinalities([scalar @$conditionalProbabilityTable]);
  my $prob = 0;
  my $probTot = 0;
  my $i;
  for ($i = 0; $i < (scalar (@$conditionalProbabilityTable)-1) ; $i++) {
    $prob = $conditionalProbabilityTable->[$i];
    $probTot += $prob;
    #print "Prob: $prob\n";
    $multinomial->setP([$i],$prob);
  }
  $multinomial->setP([$i],1-$probTot);
  $multinomial->prepareForSampling();
  $CPTHash->{1} = $multinomial;
}

sub generateObservation {
  my ($self) = @_;
  
  my $row = [];
  my $numAttributes = $self->getSchema()->getNumAttributes();
  for (my $i = 0; $i < $numAttributes; $i++) {
    $row->[$i] = undef;
  }
  for (my $i = 0; $i < $numAttributes; $i++) {
    $self->generateValue($row,$i);
  }
  return $row;
}

sub generateValue {
  my ($self,$row,$i) = @_;

  my $parents = $self->getParents($i);
  my $CPTHash = $self->getCPTHash()->{$i};
  foreach my $parent (@$parents) {
    if (!defined $row->[$parent]) {
      $self->generateValue($row,$parent);
    }
    $CPTHash = $CPTHash->{$row->[$parent]};
  }
  if (!defined $row->[$i]) {
    my $valIndex= $CPTHash->{1}->sample()->[0];
    #print "Val gen: $valIndex\n";
    $row->[$i] = $self->getSchema()->getAttributeByPos($i)->getType()->getValue($valIndex);
  }
}

sub toString {
  my ($self) = @_;

  my $graph = $self->getGraph();
  my $CPTHash = $self->getCPTHash();

  foreach my $node (@{$graph->getNodes()}) {
    print "Node: $node\n";
    my $parents = $self->getParents($node);
    print "\tParents:";
    foreach my $parent (@$parents) {
      print " $parent";
    }
    print "\n";
    my $nodeCPT = $CPTHash->{$node};
    $self->recPrintCPT($nodeCPT,$parents,[]);
  }
}

sub recPrintCPT {
  my ($self,$nodeCPT,$parents,$parentValues) = @_;
  
  if (scalar (@$parents) == 0) {
    print "CPT for ".join(",",@$parentValues).":\n";
    print join(",",$nodeCPT->{1}->toList())."\n";
  } else {
    my @newParents = @$parents;
    shift @newParents;
    foreach my $val (keys %$nodeCPT) {
      push @$parentValues,$val;
      $self->recPrintCPT($nodeCPT->{$val},\@newParents,$parentValues);
      pop @$parentValues;
    }
  }
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
    #print @class_values,"\n";
    #print join(',',@class_values),"\n";
    my $tmp = $row_to_classify->[$class_attno];
    foreach $class_val (@class_values)
      {
	#print "Class = $class_val, cv[0] = ",$class_values[0]," \n";
	#print $countClass{$class_val},"\n";

	# Assign value to the class
	$row_to_classify->[$class_attno] = $class_val;
	
	# Calculate the probability
	$Prob{$class_val} = $self->calculateObservationProbability($row_to_classify);
      }
    $row_to_classify->[$class_attno] = $tmp;
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
#      {
#	print "P($class_val) = ",$condProb{$class_val},","; 
#      }
#    print "\n";
    return ([\%condProb,$max,\%Prob,$sum]);
  }


sub calculateObservationProbability {
  my ($self,$row) = @_;
  
  my $pRow = [];
  my $numAttributes = $self->getSchema()->getNumAttributes();
  #for (my $i = 0; $i < $numAttributes; $i++) {
  #  $pRow->[$i] = undef;
  #}
  my $totalP = 1;
  for (my $i = 0; $i < $numAttributes; $i++) {
    $totalP = $totalP * $self->calculateValueProbability($row,$i);
  }
  return $totalP;
}

sub calculateValueProbability {
  my ($self,$row,$i) = @_;
  
  my $parents = $self->getParents($i);
  my $CPTHash = $self->getCPTHash()->{$i};
  foreach my $parent (@$parents) {
    $CPTHash = $CPTHash->{$row->[$parent]};
  }
  my $value = $row->[$i];
  my $valuePos = $self->getSchema()->getAttributeByPos($i)->getType()->getValuePosition($value);
  my $p= $CPTHash->{1}->getP([$valuePos]);
  return $p;
  #print "Val gen: $valIndex\n";
  #$row->[$i] = $self->getSchema()->getAttributeByPos($i)->getType()->getValue($valIndex);
  #}
}


sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

1;
