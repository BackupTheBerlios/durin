package Durin::RODE::RODEDecomposable;

use base "Durin::Classification::Model";

use Class::MethodMaker
  get_set => [ -java => qw/CountTable Alphas EquivalentSampleSize N N_u N_uv Indexes ClassAttIndex StructureStubbornness/];


use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;
use Math::Gsl::Sf;
use ntl;

use strict;
use warnings;

use constant NoStubbornness => "1";
use constant HardMinded => "2";
use constant Constant => "3";


sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setCountTable(undef);
  # Structure stubbornness can be one of NoStubbornness,HardMinded,Constant
  # No stubbornness means TBMATAN.
  # HardMinded means softening the betas to make them all over 10E-3.
  # Constant means no change in betas.
  $self->setStructureStubbornness(NoStubbornness);
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
  $self->refineNs();
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
  
  #if ($self->getStructureStubbornness() eq HardMinded) {
  #  $log_ro_u = $self->softenRos($log_ro_u);
  #}
  
  my $alphas = $self->getAlphas();
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      $alphas->[$node_u] = $alphas->[$node_u] * exp($log_ro_u->[$node_u]);
    }
  }
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
  
  foreach my $class_val_iter (@class_values) {
    foreach my $u_val (@u_values) {
      print STDERR "LA\n";
      my $nquote_uc = $self->N_u($node_u,$u_val,$class_val_iter);
      my $n_uc = $ct->getCountXClass($class_val_iter,$node_u,$u_val);
      print STDERR  "LO\n";

      my $log_first_factor = ($numClassValues - 3) * (Math::Gsl::Sf::lngamma($nquote_uc) - Math::Gsl::Sf::lngamma($nquote_uc + $n_uc)); 
      $log_ro_u += $log_first_factor;
      for(my $node_v = 0 ; $node_v < $num_atts; $node_v++) {
	if (($node_v != $class_attno) && ($node_v != $node_u)) { 
	  my $att_v = $schema->getAttributeByPos($node_v);
	  my @v_values = @{$att_v->getType()->getValues()};
	  foreach my $v_val (@v_values) {
	    my $n_ucv = $ct->getCountXYClass($class_val_iter,$node_u,$u_val,$node_v,$v_val);
	    my $nquote_ucv = $self->N_uv($node_u,$node_v,$u_val,$v_val,$class_val_iter);
	    $log_ro_u += Math::Gsl::Sf::lngamma($n_ucv+$nquote_ucv) - Math::Gsl::Sf::lngamma($nquote_ucv);
	    #print "LnGamma($count+$nquote+$beta)=$lnGamma\n";
	  }
	}
      }
    }
  }
  return $log_ro_u;
}


sub setEquivalentSampleSizeAndInitialize {
  my ($self,$size) = @_;  
  
  $self->setEquivalentSampleSize($size);
  $self->initializeSampleSize();
}

sub initializeSampleSize {
  my ($self) = @_;

  my $lambda = $self->getEquivalentSampleSize();
  my $schema = $self->getSchema();
  my $class_attno = ($schema->getClassPos());
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $num_classes = scalar (@{$class_att->getType->getValues()});
  my $num_atts = $schema->getNumAttributes();


  $self->setClassAttIndex($class_attno);
  
  # For every attribute we create a map from values to integers
  
  $self->setIndexes([]);
  foreach my $att (0..$num_atts-1)
    {
      my @att_values = @{$schema->getAttributeByPos($att)->getType()->getValues()};
      my $map = {};
      my $index = 0;
      foreach my $att_val (@att_values)
	{
	  $map->{$att_val} = $index;
	  $index++;
	}
      push @{$self->getIndexes()},$map;
    }
  
  # The general counter
  
  $self->setN(0);
  
  # Att x Class pidls
  
  $self->setN_u([]);
  foreach my $att (0..$num_atts-1)
    {
      my @att_values = @{$schema->getAttributeByPos($att)->getType()->getValues()};
      my $num_att_values = scalar(@att_values);
      print STDERR  "M\n";
      my $array = ones $num_att_values,$num_classes;
      $array = $array * ($lambda / ($num_att_values * $num_classes));
      push @{$self->getN_u()},$array;
      print STDERR  "N\n";
    }
  
  # Att x Att x Class pidls
  
  $self->setN_uv([]);
  
  foreach my $att1 (0..$num_atts-1)
    {
      if ($att1 != $class_attno)
	{
	  my @att_values1 = @{$schema->getAttributeByPos($att1)->getType()->getValues()};
	  #print join(',',@att_values1)."\n";
	  my $num_att_values1 = scalar(@att_values1);
	  #print "Num att values = $num_att_values1\n";
	  foreach my $att2 (0..$att1-1)
	    {
	      if ($att2 != $class_attno)
		{
		  my @att_values2 = @{$schema->getAttributeByPos($att2)->getType()->getValues()};
		  my $num_att_values2 = scalar(@att_values2);
		  print STDERR  "M2\n";
		  my $array = ones $num_att_values1,$num_att_values2,$num_classes;
		  $array = $array * ($lambda / ($num_att_values1 * $num_att_values2 * $num_classes));
		  $self->getN_uv()->[$att1][$att2] = $array;
		  print STDERR  "N2\n";
		}
	    }
	}
    }
}

sub N_u {
  my ($self,$u,$u_val,$class_val) = @_;
  print STDERR  "A\n";
  my $class_attno = $self->getClassAttIndex();
  my $class_val_index = $self->getIndexes()->[$class_attno]->{$class_val};
  my $u_val_index = $self->getIndexes()->[$u]->{$u_val};
  my $temp = $self->getN_u()->[$u]->at($u_val_index,$class_val_index);
  print STDERR  "B\n";
  return $temp;
}

sub N_uv  {
  my ($self,$u,$v,$u_val,$v_val,$class_val) = @_;
  
  print STDERR "C\n";
  if ($u==$v) {
    die "Durin::RODEDecomposable::getCountXYClass \$x equal \$y\n";
  }
  if ($u < $v) {
    my $tmp = $u;
    $u = $v;
    $v = $tmp;
    $tmp = $v_val;
    $v_val = $u_val;
    $u_val = $tmp;
  }
  
  my $class_attno = $self->getClassAttIndex();
  my $class_val_index = $self->getIndexes()->[$class_attno]->{$class_val};
  my $u_val_index = $self->getIndexes()->[$u]->{$u_val};
  my $v_val_index = $self->getIndexes()->[$v]->{$v_val};
  print STDERR  "D $u $v $u_val $u_val_index $v_val $v_val_index $class_val $class_val_index\n";
  my $temp = $self->getN_uv()->[$u][$v]->at($u_val_index,$v_val_index,$class_val_index);  
  print STDERR "E\n";
  #print $temp;
  return $temp;
}

sub refineNs {
  my ($self) = @_;
  
  my $schema = $self->getSchema();
  my $num_atts = $schema->getNumAttributes();
  my $ct = $self->getCountTable();
  my $class_attno = $self->getClassAttIndex();

  for(my $node_u = 0 ; $node_u < $num_atts ; $node_u++) {
    if ($node_u != $class_attno)  { 
      $self->getN_u()->[$node_u] += $ct->getXClassTable($node_u);
    }
    for(my $node_v = 0 ; $node_v < $node_u; $node_v++) {
      if ($node_v != $class_attno)  { 
	$self->getN_uv()->[$node_u][$node_v] += $ct->getXYClassTable($node_u,$node_v);
      }
    }
  }
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
  foreach my $class_val (@class_values) {
    $Prob{$class_val} = 0.0;
    for(my $node_u = 0 ; $node_u < $num_atts ; $node_u++) {
      if ($node_u != $class_attno)  {
	$Prob{$class_val} += $self->computeProbConcreteModel($node_u,$row_to_classify,$class_val);
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

  my $u_val = $row_to_classify->[$node_u];
  my $N_uc = $self->N_u($node_u,$u_val,$class_val);
  my $prob = $N_uc;
  for(my $node_v = 0 ; $node_v < $num_atts; $node_v++) {
    if (($node_v != $class_attno) && ($node_v != $node_u)) { 
      my $v_val = $row_to_classify->[$node_v];
      my $factor = $self->N_uv($node_u,$node_v,$u_val,$v_val,$class_val) / $N_uc;
      $prob *= $factor;
    }
  }
  return $prob;
}

1;
