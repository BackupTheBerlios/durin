package Durin::RODE::AODEModel;

use base "Durin::Classification::Model";

use Class::MethodMaker
  get_set => [ -java => qw/CountTable EquivalentSampleSize MinimumCount/];


use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;
use Math::Gsl::Sf;
use ntl;

use strict;
use warnings;

sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setCountTable(undef);
  
  $self->setMinimumCount(30);
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::TAN::TAN clone not implemented";
}

sub learn  {
  my ($self,$ct) = @_;
  
  $self->setCountTable($ct);

  # And calculate the Wuv
  
}

sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

sub predict {
  my ($self,$row_to_classify) = @_;
  
  my %Prob;

  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my @class_values = @{$class_att->getType()->getValues()};
  my $numClasses = scalar(@class_values);
  my $num_atts = $schema->getNumAttributes();
  my $ct = $self->getCountTable();
  
  my $numModelsApplied = 0;
  my $m = $self->getMinimumCount();
  
  foreach my $class_val (@class_values) {
    $Prob{$class_val} = 0.0;
  }
  
  for(my $node_u = 0 ; $node_u < $num_atts ; $node_u++) {
    if ($node_u != $class_attno)  {
      if ($m < $ct->getCountX($node_u,$row_to_classify->[$node_u])) {
	$numModelsApplied++;
	#print "applying rode model $numModelsApplied\n";
	foreach my $class_val (@class_values) {
	  $Prob{$class_val} += $self->computeProbConcreteModel($node_u,$row_to_classify,$class_val);
	}
      }
    }
  }

  if ($numModelsApplied == 0) {
    #print "Applying Naive Bayes\n";
    # Apply naive Bayes
    foreach my $class_val (@class_values) {
      my $pThisClass = ($ct->getCountClass($class_val) + 1) / ($ct->getCount() + $numClasses);
      $Prob{$class_val} = $pThisClass;
      for(my $node_u = 0 ; $node_u < $num_atts ; $node_u++) {
	if ($node_u != $class_attno)  {
	  my $numValues_u = scalar(@{$schema->getAttributeByPos($node_u)->getType()->getValues()});	
	  my $num = $ct->getCountXClass($class_val,$node_u,$row_to_classify->[$node_u]) + 1;
	  my $den = $ct->getCount() + ($numClasses * $numValues_u);
	  $Prob{$class_val} *= ($num / ($den * $pThisClass));
	}
      }
    }
  }
  
  #foreach my $class_val (@class_values)
  #  {
  #    print "P($class_val) = ",$Prob{$class_val},",";
  #  }
  #print "\n";

  my $sum = 0;
  my $max = 0;
  my $probMax = 0;
  foreach my $class_val (@class_values) {
    if ($probMax < $Prob{$class_val}) {
      $probMax = $Prob{$class_val};
      $max = $class_val;
    }
    $sum += $Prob{$class_val};
  }
  if ($sum != 0) {
    foreach my $class_val (@class_values) {
      $Prob{$class_val} = $Prob{$class_val}/$sum; 
    }
  } else {
    foreach my $class_val (@class_values) {
      $Prob{$class_val} = 1 / ($#class_values + 1); 
    }
  }
  
  #foreach my $class_val (@class_values)
  #  {
  #    print "P($class_val) = ",$Prob{$class_val},",";
  #  }
  
  return ([\%Prob,$max]);
}

sub computeProbConcreteModel {
  my ($self,$node_u,$row_to_classify,$class_val) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $numClasses = scalar(@{$class_att->getType()->getValues()});
  my $numValues_u = scalar(@{$schema->getAttributeByPos($node_u)->getType()->getValues()});	
  
  my $num_atts = $schema->getNumAttributes();
  my $ct = $self->getCountTable();
  
  my $u_val = $row_to_classify->[$node_u];
  my $N_uc = $ct->getCountXClass($class_val,$node_u,$u_val);
  my $N = $ct->getCount();
  
  my $p_uc = ($N_uc + 1) / ($N + ($numClasses*$numValues_u)); 
  my $prob = $p_uc;
  for(my $node_v = 0 ; $node_v < $num_atts; $node_v++) {
    if (($node_v != $class_attno) && ($node_v != $node_u)) { 
      my $numValues_v = scalar(@{$schema->getAttributeByPos($node_v)->getType()->getValues()});	
      my $v_val = $row_to_classify->[$node_v];
      my $p_uvc = ($ct->getCountXYClass($class_val,$node_u,$u_val,$node_v,$v_val) + 1) / ($N + ($numClasses*$numValues_u*$numValues_v));
      $prob *= ($p_uvc/$p_uc);
    }
  }
  return $prob;
}

1;
