package Durin::RODE::RODEDecomposable2;

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
      push @$log_ro_u,0;
    }
  }
  
  print "original log_ros: ".join(",",@$log_ro_u)."\n";

  $self->softenLogRos($log_ro_u);

  my $alphas = $self->getAlphas();
  print "prior alphas:".join(",",@$alphas)."\n";
  print "log_ros: ".join(",",@$log_ro_u)."\n";
  
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      $alphas->[$node_u] = $alphas->[$node_u] * exp($log_ro_u->[$node_u]);
    }
  }
  print "posterior alphas:".join(",",@$alphas)."\n";
}

sub lngammadif {
  my ($self,$a,$b) = @_;

  return Math::Gsl::Sf::lngamma($a+$b) - Math::Gsl::Sf::lngamma($a);
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
      if ($node_u != $class_attno) {
	#print "We enter with $lnWuv\n";
	$log_ro_u->[$node_u] = $a*($log_ro_u->[$node_u])+$b; 
	#print "And we get out with $lnWuv\n";
      }
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
      if ($node_u != $class_attno) {
	#print "We enter with $lnWuv\n";
	$log_ro_u->[$node_u] = $a*($log_ro_u->[$node_u])+$b; 
	#print "And we get out with $lnWuv\n";
      }
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
    if ($node_u != $class_attno) {
      my $lnWuv = $log_ro_u->[$node_u];
      if ((!defined $min) || ($min > $lnWuv)) {
	$min = $lnWuv;
      }
      if ((!defined $max) || ($max < $lnWuv)) {
	$max = $lnWuv;
      }
    }
  }
  return [$min,$max];
}
#sub setEquivalentSampleSizeAndInitialize {
#  my ($self,$size) = @_;  
#  
#  $self->setEquivalentSampleSize($size);
#  $self->initializeSampleSize();
#}

#sub initializeSampleSize {
#  my ($self) = @_;

#  my $lambda = $self->getEquivalentSampleSize();
#  my $schema = $self->getSchema();
#  my $class_attno = ($schema->getClassPos());
#  my $class_att = $schema->getAttributeByPos($class_attno);
#  my $num_classes = scalar (@{$class_att->getType->getValues()});
#  my $num_atts = $schema->getNumAttributes();


#  $self->setClassAttIndex($class_attno);
  
#  # For every attribute we create a map from values to integers
  
#  $self->setIndexes([]);
#  foreach my $att (0..$num_atts-1)
#    {
#      my @att_values = @{$schema->getAttributeByPos($att)->getType()->getValues()};
#      my $map = {};
#      my $index = 0;
#      foreach my $att_val (@att_values)
#	{
#	  $map->{$att_val} = $index;
#	  $index++;
#	}
#      push @{$self->getIndexes()},$map;
#    }
  
#  # The general counter
  
#  $self->setN(0);
  
#  # Att x Class pidls
  
#  $self->setN_u([]);
#  foreach my $att (0..$num_atts-1)
#    {
#      my @att_values = @{$schema->getAttributeByPos($att)->getType()->getValues()};
#      my $num_att_values = scalar(@att_values);
#      #print STDERR  "M\n";
#      my $array = ones $num_att_values,$num_classes;
#      $array = $array * ($lambda / ($num_att_values * $num_classes));
#      push @{$self->getN_u()},$array;
#      #print STDERR  "N\n";
#    }
  
#  # Att x Att x Class pidls
  
#  $self->setN_uv([]);
  
#  foreach my $att1 (0..$num_atts-1)
#    {
#      if ($att1 != $class_attno)
#	{
#	  my @att_values1 = @{$schema->getAttributeByPos($att1)->getType()->getValues()};
#	  #print join(',',@att_values1)."\n";
#	  my $num_att_values1 = scalar(@att_values1);
#	  #print "Num att values = $num_att_values1\n";
#	  foreach my $att2 (0..$att1-1)
#	    {
#	      if ($att2 != $class_attno)
#		{
#		  my @att_values2 = @{$schema->getAttributeByPos($att2)->getType()->getValues()};
#		  my $num_att_values2 = scalar(@att_values2);
#		  #print STDERR  "M2\n";
#		  my $array = ones $num_att_values1,$num_att_values2,$num_classes;
#		  $array = $array * ($lambda / ($num_att_values1 * $num_att_values2 * $num_classes));
#		  $self->getN_uv()->[$att1][$att2] = $array;
#		  #print STDERR  "N2\n";
#		}
#	    }
#	}
#    }
#}

#sub N_u {
#  my ($self,$u,$u_val,$class_val) = @_;
#  #print STDERR  "A\n";
#  my $class_attno = $self->getClassAttIndex();
#  my $class_val_index = $self->getIndexes()->[$class_attno]->{$class_val};
#  my $u_val_index = $self->getIndexes()->[$u]->{$u_val};
#  my $temp = $self->getN_u()->[$u]->at($u_val_index,$class_val_index);
#  #print STDERR  "B\n";
#  return $temp;
#}

#sub N_uv  {
#  my ($self,$u,$v,$u_val,$v_val,$class_val) = @_;
  
#  #print STDERR "C\n";
#  if ($u==$v) {
#    die "Durin::RODEDecomposable::getCountXYClass \$x equal \$y\n";
#  }
#  if ($u < $v) {
#    my $tmp = $u;
#    $u = $v;
#    $v = $tmp;
#    $tmp = $v_val;
#    $v_val = $u_val;
#    $u_val = $tmp;
#  }
  
#  my $class_attno = $self->getClassAttIndex();
#  my $class_val_index = $self->getIndexes()->[$class_attno]->{$class_val};
#  my $u_val_index = $self->getIndexes()->[$u]->{$u_val};
#  my $v_val_index = $self->getIndexes()->[$v]->{$v_val};
#  #print STDERR  "D $u $v $u_val $u_val_index $v_val $v_val_index $class_val $class_val_index\n";
#  my $temp = $self->getN_uv()->[$u][$v]->at($u_val_index,$v_val_index,$class_val_index);  
#  #print STDERR "E\n";
#  #print $temp;
#  return $temp;
#}

#sub refineNs {
#  my ($self) = @_;
  
#  my $schema = $self->getSchema();
#  my $num_atts = $schema->getNumAttributes();
#  my $ct = $self->getCountTable();
#  my $class_attno = $self->getClassAttIndex();
  
#  for(my $node_u = 0 ; $node_u < $num_atts ; $node_u++) {
#    if ($node_u != $class_attno)  {
#      $self->getN_u()->[$node_u] += $ct->getXClassTable($node_u);
#      for(my $node_v = 0 ; $node_v < $node_u; $node_v++) {
#        if ($node_v != $class_attno)  { 
#	  $self->getN_uv()->[$node_u][$node_v] += $ct->getXYClassTable($node_u,$node_v);
#        }
#      }
#    }
#  }
#}

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
