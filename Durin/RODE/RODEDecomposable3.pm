
# This one averages with Naive Bayes also

package Durin::RODE::RODEDecomposable3;

use base "Durin::Classification::Model";

use Class::MethodMaker
  get_set => [ -java => qw/CountTable Alphas EquivalentSampleSize N N_u N_uv Indexes ClassAttIndex StructureStubbornness ParameterizedStubbornnessFactor/];


use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;
use Math::Gsl::Sf;
use ntl;

use strict;
use warnings;

use constant NoStubbornness => "NoStubbornness"; # This is normal Bayesian Model Averaging
use constant ParameterizedStubbornness => "Parameterized"; # This is Bayesian Model Averaging, but with a factor limiting how much can an observation change astructure probability.
use constant AbsolutelyStubborn => "AbsolutelyStubborn"; # No refinement is made on prior assumptions (no structure learning)


sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setCountTable(undef);
  
  $self->setStructureStubbornness(NoStubbornness);
  $self->setParameterizedStubbornnessFactor(0.95);
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
  
  $self->refineAlphas();
  #$self->refineNs();
}

sub refineAlphas {
  my ($self) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();
  my $max_log_ro_u = -12302342342342234291823091123.4;
  my $log_ro_u = [];
  my $reductionFactor = undef;
  
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      my $tmp = $self->computeLogRo($node_u);
      push @$log_ro_u,$tmp;
      if($tmp > $max_log_ro_u) {
	$max_log_ro_u = $tmp;
      }
    } else {
      push @$log_ro_u,$self->computeLogRoNaive();
    }
  }

  print "class is attribute number $class_attno\n";
  print "original log_ros: ".join(",",@$log_ro_u)."\n";
  
  $self->softenLogRos($log_ro_u);

  my $alphas = $self->getAlphas();
  print "prior alphas:".join(",",@$alphas)."\n";
  print "log_ros: ".join(",",@$log_ro_u)."\n";
  
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    #if ($node_u != $class_attno) {
      $alphas->[$node_u] = $alphas->[$node_u] * exp($log_ro_u->[$node_u]);
      #}
  }
  print "posterior alphas:".join(",",@$alphas)."\n";
}

sub lngammadif {
  my ($self,$a,$b) = @_;

  return Math::Gsl::Sf::lngamma($a+$b) - Math::Gsl::Sf::lngamma($a);
}


sub computeLogRoNaive {
  my($self) = @_;
  
  my $log_ro_u = 0.0;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my @class_values = @{$class_att->getType()->getValues()};
  my $numClassValues = scalar(@class_values);
  my $num_atts = $schema->getNumAttributes();
  
  my $ct = $self->getCountTable();
  
  my $N = $ct->getCount();
  my $N_quote_c = $self->getN_Quote_c();
  
  $log_ro_u -= $self->lngammadif($N_quote_c,$N);
  
  foreach my $class_val_iter (@class_values) {
    my $N_c = $ct->getCountClass($class_val_iter);
    my $N_quote_c_c = $self->getN_Quote_c_c($class_val_iter);
    $log_ro_u += $self->lngammadif($N_quote_c_c,$N_c);
    for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
      if ($node_u != $class_attno)  {
	my $N_quote_c_uc = $self->getN_Quote_c_uc($class_val_iter,$node_u); 
	$log_ro_u -= $self->lngammadif($N_quote_c_uc,$N_c);
	my $att_u = $schema->getAttributeByPos($node_u);
	my @u_values = @{$att_u->getType()->getValues()};
	foreach my $u_val (@u_values) {
	  my $N_quote_uc_uc = $self->getN_Quote_uc_uc($u_val,$class_val_iter,$node_u);
	  my $N_uc = $ct->getCountXClass($class_val_iter,$node_u,$u_val);
	  $log_ro_u += $self->lngammadif($N_quote_uc_uc,$N_uc);
	}
      }
    }
  }
  return $log_ro_u;
}


sub computeLogRo {
  my($self,$node_u) = @_;
  
  my $log_ro_u = 0.0;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my @class_values = @{$class_att->getType()->getValues()};
  my $numClassValues = scalar(@class_values);
  my $att_u = $schema->getAttributeByPos($node_u);
  my @u_values = @{$att_u->getType()->getValues()};
  my $num_atts = $schema->getNumAttributes();
  
  my $ct = $self->getCountTable();
  
  my $N = $ct->getCount();
  my $N_quote_u = $self->getN_Quote_u($node_u);
  
  $log_ro_u -= $self->lngammadif($N_quote_u,$N);
  
  foreach my $class_val_iter (@class_values) {
    foreach my $u_val (@u_values) {
      my $N_quote_uc_u = $self->getN_Quote_uc_u($u_val,$class_val_iter,$node_u);
      my $N_uc = $ct->getCountXClass($class_val_iter,$node_u,$u_val);
      $log_ro_u += $self->lngammadif($N_quote_uc_u,$N_uc);
      for(my $node_v = 0 ; $node_v < $num_atts; $node_v++) {
	if (($node_v != $class_attno) && ($node_v != $node_u)) { 
	  my $N_quote_uc_uv = $self->getN_Quote_uc_uv($u_val,$class_val_iter,$node_u,$node_v);
	  $log_ro_u -= $self->lngammadif($N_quote_uc_uv,$N_uc);
	  
	  my $att_v = $schema->getAttributeByPos($node_v);
	  my @v_values = @{$att_v->getType()->getValues()};
	  foreach my $v_val (@v_values) {
	    my $N_quote_vuc_uv = $self->getN_Quote_vuc_uv($v_val,$u_val,$class_val_iter,$node_u,$node_v);
	    my $N_vuc = $ct->getCountXYClass($class_val_iter,$node_u,$u_val,$node_v,$v_val);
	    $log_ro_u += $self->lngammadif($N_quote_vuc_uv,$N_vuc);
	  }
	}
      }
    }
  }
  return $log_ro_u;
}

sub softenLogRos {
  my ($self,$log_ro_u) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  print "My stubbornness is".$self->getStructureStubbornness()."\n";
  if ($self->getStructureStubbornness() eq ParameterizedStubbornness) { 
    my $ct = $self->getCountTable();
    #my $schema = $self->getSchema();
    my $N = $ct->getCount();
    my $f = $self->getParameterizedStubbornnessFactor();
    print "Parameterized stubbornness: $f\n";
    my $log_max_dif = abs($N * log $f);
    if ($log_max_dif > 200) {
      $log_max_dif = 200;
    }
    print "LogMaxDif = $log_max_dif\n";
    #my $schema = $self->getSchema();
    my ($min,$max) = @{$self->calculateMinMax($log_ro_u)};
    my $StMin = -$log_max_dif;
    my $StMax = 0;
    if (($max-$min) < $log_max_dif) {
      # Do never exagerate beliefs. If the difference 
      # is not so marked keep it as it is and just move 
      # it to be around 0 ($a will be 1).
      $StMin = $StMax-($max-$min);
    }
    print "Max-Min = $max, $min\n";
    my ($a,$b);
    if (($max-$min) > 0.0000000001) {
      $a = ($StMax-$StMin)/($max-$min);
      #$b = $StMin-$a*$min;
      $b = $StMax - $a*$max;
      print "a = $a, b = $b\n";
    } else {
      print "Almost no diff\n";
      $a = $StMin/$max;
      $b = 0;
    }
    
    foreach my $node_u (0..(scalar(@$log_ro_u)-1)) {
      #print "We enter with $lnWuv\n";
      $log_ro_u->[$node_u] = $a*($log_ro_u->[$node_u])+$b; 
      #print "And we get out with $lnWuv\n";
    }
  }
  elsif ($self->getStructureStubbornness() eq AbsolutelyStubborn) {
    print "Absolutely stubborn\n";
    foreach my $i (0..(scalar(@$log_ro_u)-1)) {
      $log_ro_u->[$i] = 0;
    }
  } elsif ($self->getStructureStubbornness() eq NoStubbornness){
    my $log_max_dif = 200;
    my ($min,$max) = @{$self->calculateMinMax($log_ro_u)};
    my $StMin = -$log_max_dif;
    my $StMax = 0;
    if (($max-$min) < $log_max_dif) {
      # Do never exagerate beliefs. If the difference 
      # is not so marked keep it as it is and just move 
      # it to be around 0 ($a will be 1).
      $StMin = $StMax-($max-$min);
    }
    print "Max-Min = $max, $min\n";
    my ($a,$b);
    if (($max-$min) > 0.0000000001) {
      $a = ($StMax-$StMin)/($max-$min);
      $b = $StMax - $a*$max;
      print "a = $a, b = $b\n";
    } else {
      print "Almost no diff\n";
      $a = $StMin/$max;
      $b = 0;
    }
    
    foreach my $node_u (0..(scalar(@$log_ro_u)-1)) {
      #print "We enter with $lnWuv\n";
      $log_ro_u->[$node_u] = $a*($log_ro_u->[$node_u])+$b; 
      #print "And we get out with $lnWuv\n";
    }
    print "No stubbornness\n";
  }
}

sub calculateMinMax {
  my ($self,$log_ro_u) = @_;
  
  my $min = undef;
  my $max = undef;
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  foreach my $node_u (0..(scalar(@$log_ro_u)-1)) {
    my $lnWuv = $log_ro_u->[$node_u];
    if ((!defined $min) || ($min > $lnWuv)) {
      $min = $lnWuv;
    }
    if ((!defined $max) || ($max < $lnWuv)) {
      $max = $lnWuv;
    }
  }
  return [$min,$max];
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
  my $num_atts = $schema->getNumAttributes();
  my $alphas = $self->getAlphas();
  foreach my $class_val (@class_values) {
    $Prob{$class_val} = 0.0;
    for(my $node_u = 0 ; $node_u < $num_atts ; $node_u++) {
      if ($node_u != $class_attno)  {
	$Prob{$class_val} += $alphas->[$node_u] * $self->computeProbConcreteModel($node_u,$row_to_classify,$class_val);
      } else {
	$Prob{$class_val} += $alphas->[$node_u] * $self->computeProbNaiveModel($row_to_classify,$class_val);
      }
    }
    #$self->CalculateValueProportionalToPClass($row_to_classify,$class_val)->sclr;
  }
  
  # Normalization of probabilities & calculation of the most probable class
  #foreach $class_val (@class_values)
  #  {
  #    print "P($class_val) = ",$Prob{$class_val},",";
  #  }
  #print "\n After normalization:\n";
  
  my $sum = 0; 
  my $max = 0;
  my $probMax = 0;
  foreach my $class_val (@class_values) {
    if ($probMax<$Prob{$class_val}) {
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
  
  #foreach $class_val (@class_values)
  #  {
  #    print "P($class_val) = ",$Prob{$class_val},",";
  #  }
  
  return ([\%Prob,$max]);
}

sub computeProbConcreteModel {
  my ($self,$node_u,$row_to_classify,$class_val) = @_;

  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $num_atts = $schema->getNumAttributes();
  my $ct = $self->getCountTable();
  my $u_val = $row_to_classify->[$node_u];
  
  
  my $N = $ct->getCount();
  my $N_quote_u = $self->getN_Quote_u($node_u);
  
  my $N_quote_uc_u = $self->getN_Quote_uc_u($u_val,$class_val,$node_u);
  my $N_uc = $ct->getCountXClass($class_val,$node_u,$u_val);

  my $prob = ($N_uc + $N_quote_uc_u) / ($N + $N_quote_u);
  for(my $node_v = 0 ; $node_v < $num_atts; $node_v++) {
    if (($node_v != $class_attno) && ($node_v != $node_u)) { 
      my $v_val = $row_to_classify->[$node_v];
      my $N_quote_uc_uv = $self->getN_Quote_uc_uv($u_val,$class_val,$node_u,$node_v);
      my $N_quote_vuc_uv = $self->getN_Quote_vuc_uv($v_val,$u_val,$class_val,$node_u,$node_v);
      my $N_vuc = $ct->getCountXYClass($class_val,$node_u,$u_val,$node_v,$v_val);      
      
      my $factor = ($N_vuc + $N_quote_vuc_uv) / ($N_uc + $N_quote_uc_uv); 
      $prob *= $factor;
    }
  }
  return $prob;
}

sub computeProbNaiveModel {
  my ($self,$row_to_classify,$class_val) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $num_atts = $schema->getNumAttributes();
  my $ct = $self->getCountTable();
  
  my $N = $ct->getCount();
  my $N_quote_c = $self->getN_Quote_c();
  
  my $N_c = $ct->getCountClass($class_val);
  my $N_quote_c_c = $self->getN_Quote_c_c($class_val);  
  
  my $prob = ($N_c + $N_quote_c_c) / ($N + $N_quote_c);
  
  for(my $node_u = 0 ; $node_u < $num_atts; $node_u++) {
    if ($node_u != $class_attno) { 
      my $u_val = $row_to_classify->[$node_u];
      my $N_quote_c_uc = $self->getN_Quote_c_uc($class_val,$node_u); 
      my $N_quote_uc_uc = $self->getN_Quote_uc_uc($u_val,$class_val,$node_u);      
      my $N_uc = $ct->getCountXClass($class_val,$node_u,$u_val);
      
      my $factor = ($N_uc + $N_quote_uc_uc) / ($N_c + $N_quote_c_uc); 
      $prob *= $factor;
    }
  }
  return $prob;
}

sub getN_Quote_c {
  my ($self) = @_;
  
  return $self->getCountTable()->getNumClasses();
}


sub getN_Quote_c_c {
  my ($self,$class_val) = @_;  
  
  return 1;
}

sub getN_Quote_c_uc { 
  my ($self,$class_val_iter,$node_u)  = @_;
  
  return $self->getCountTable()->getNumAttValues($node_u);
}

sub getN_Quote_uc_uc {
  my ($self,$u_val,$class_val_iter,$node_u) = @_;
  
  return 1;
}

sub getN_Quote_u {
  my ($self,$node_u) = @_;
  
  return $self->getCountTable()->getNumAttValues($node_u) * $self->getCountTable()->getNumClasses();
}

sub getN_Quote_uc_u{
  my ($self,$u_val,$class_val_iter,$node_u) = @_;
  
  return 1;
}

sub getN_Quote_uc_uv {
  my ($self,$u_val,$class_val_iter,$node_u,$node_v) = @_;
  
  return $self->getCountTable()->getNumAttValues($node_v);
}

sub getN_Quote_vuc_uv {
  my ($v_val,$u_val,$class_val_iter,$node_u,$node_v) = @_;

  return 1;
}

1;
