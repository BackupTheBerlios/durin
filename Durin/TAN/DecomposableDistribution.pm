# Stores a decomposable distribution

package Durin::TAN::DecomposableDistribution;

use strict;
use warnings;

use base 'Durin::Basic::MIManager';

use Class::MethodMaker
  get_set => [ -java => qw/EquivalentSampleSize InternalNQuoteUC InternalNQuoteUVC NQuoteC Schema CountingTable/];

use Durin::DataStructures::UGraph;
use Math::Gsl::Sf;
use PDL;


sub new_delta {
  my ($class,$self) = @_;
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub createPrior {
  my ($class,$schema,$lambda) = @_;
  
  my $newDecomposable = Durin::TAN::DecomposableDistribution->new();
  $newDecomposable->setSchema($schema);
  $newDecomposable->setEquivalentSampleSizeAndInitialize($lambda);
  
  return $newDecomposable;
}

#sub getLambda {
#  return 10;
#}

sub calculateDecomposableInf {
  my ($self,$j,$k,$class_att,$schema) = @_;
  
  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  my ($Pxyz,$Pz,$Pxz,$Pyz,$quotient,$temp,$infoTotal,$infoPartial);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  my $total = 0.0;
  my ($nquote,$n);
  my $data = $self->getCountingTable();
  foreach $class_val (@class_values) {	
    foreach $j_val (@j_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val); 
      $nquote = $self->getNQuoteUC($j);
      $n = $data->getCountXClass($class_val,$j,$j_val);
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n);
      foreach $k_val (@k_values) {
	#$nquote = $prior->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	$nquote = $self->getNQuoteUVC($j,$k);
	$n = $data->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	$total += Math::Gsl::Sf::lngamma($nquote + $n);
	$total -= Math::Gsl::Sf::lngamma($nquote);
      }
    } 
    foreach $k_val (@k_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val); 
      $nquote = $self->getNQuoteUC($k);
      $n = $data->getCountXClass($class_val,$k,$k_val);
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n);
    }
  }
  #print "Info ($j,$k) = $infoTotal\n";
  return $total;
}

sub calculateDecomposableCardinalityConsciousInf {
  my ($self,$j,$k,$class_att,$schema) = @_;
  my $data = $self->getCountingTable();
  my $logW = $self->calculateDecomposableInf($j,$k,$class_att,$schema);
  my $mu = $self->totallyIndependentInf($j,$k,$class_att,$schema);
  my $info = $logW-$mu;
  if ($info < 0) {
    print "neginfo\n";
    #$self->printInfo($j,$k,$class_att,$schema);
  }
  return $info;
}

sub printInfo {
  my ($self,$j,$k,$class_att,$schema) = @_;
  
  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  my $num_j_values = scalar @j_values;
  my $num_k_values = scalar @k_values;
  my $num_classes = scalar @class_values;
  my $total = 0.0;
  my ($nQuoteAsterisc_j,$nQuoteAsterisc_k,$n,$nuvc,$info_min);
  my $data = $self->getCountingTable();
  
  $total = 0.0;
  my ($n_j,$n_k,$n_C,$nquote);
  print "J=$j K = $k\n";
  foreach $class_val (@class_values) {	
    my $n_C = ($data->getCountClass($class_val)); 
    print "N_C = $n_C\n";
    foreach $j_val (@j_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val); 
      $nquote = $self->getNQuoteUC($j);
      $n = $data->getCountXClass($class_val,$j,$j_val);
      print "C=$class_val, J=$j_val Prior=$nquote Count=$n\n";
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n_C/$num_j_values);
    }
    foreach $k_val (@k_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val); 
      $nquote = $self->getNQuoteUC($k);
      $n = $data->getCountXClass($class_val,$k,$k_val);
      print "C=$class_val, K=$k_val Prior=$nquote Count=$n\n";
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n_C/$num_k_values);
    }
    my $tt_infoReal = 0.0;
    my $tt_infoIndep = 0.0;
    foreach $j_val (@j_values) {
      $n_j = $data->getCountXClass($class_val,$j,$j_val);
      my $t_infoReal = 0.0;
      my $t_infoIndep = 0.0;
      foreach $k_val (@k_values) {
	$n_k = $data->getCountXClass($class_val,$k,$k_val);
	#$nquote = $prior->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	$nquote = $self->getNQuoteUVC($j,$k);
	$n_C = $data->getCountClass($class_val);
	if ($n_C > 0) {
	  $n = ($n_k * $n_j)/$n_C;
	} else {
	  $n = 0;
	}
	my ($infoIndep,$infoReal);
	$infoIndep = 0.0;
	$infoReal = 0.0;
	#if ($n > 0.0) {
	$infoIndep = Math::Gsl::Sf::lngamma($n_C/($num_j_values * $num_k_values) + $nquote);
	$t_infoIndep += $infoIndep;
	#}
	my $n_dep = $data->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	#if ($n_dep > 0) {
	$infoReal = Math::Gsl::Sf::lngamma($n_dep + $nquote);
	$t_infoReal += $infoReal;
	#}
	print "C=$class_val, J=$j_val, K=$k_val Prior=$nquote IndepCount=$n RealCount=$n_dep IndepInfo:$infoIndep RealInfo:$infoReal\n";
	$total += Math::Gsl::Sf::lngamma($nquote + $n_C/($num_j_values+$num_k_values));
	$total -= Math::Gsl::Sf::lngamma($nquote);
      }
      print "IndepInfo:$t_infoIndep RealInfo:$t_infoReal\n";
      $tt_infoIndep += $t_infoIndep; $tt_infoReal += $t_infoReal;
    } 
    print "IndepInfoTotal:$tt_infoIndep RealInfo:$tt_infoReal\n";
  }
  print "totally 2:$total\n";
}

sub totallyIndependentInf {
  my ($self,$j,$k,$class_att,$schema) = @_;
  
  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  my $num_j_values = scalar @j_values;
  my $num_k_values = scalar @k_values;
  my $num_classes = scalar @class_values;
  my $total = 0.0;
  #my ($nQuoteAsterisc_j,$nQuoteAsterisc_k,$n,$nuvc,$info_min);
  my $data = $self->getCountingTable();
  #my $nquote = $self->getEquivalentSampleSize();
  #$n = ($data->getCount()+$nquote) / $num_classes; 
  #$nquote = $nquote/$num_classes;
  my ($nquote,$n,$n_C,$n_j,$n_k);
  my $nQuoteXYC = $self->getNQuoteUVC($j,$k);
  foreach $class_val (@class_values) {
    $n_C = $data->getCountClass($class_val);
    foreach $j_val (@j_values) {
      $nquote = $self->getNQuoteUC($j);
      $n_j = $data->getCountXClass($class_val,$j,$j_val);
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n_j);
    }
    foreach $k_val (@k_values) {
      $nquote = $self->getNQuoteUC($k);
      $n_k = $data->getCountXClass($class_val,$k,$k_val);
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n_k);
    }
    foreach $j_val (@j_values) {
      $n_j = $data->getCountXClass($class_val,$j,$j_val);
      foreach $k_val (@k_values) {
	$n_k = $data->getCountXClass($class_val,$k,$k_val);
	#$nquote = $prior->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	$nquote = $self->getNQuoteUVC($j,$k);
	#$n_C = $data->getCountClass($class_val);
	if ($n_C > 0) {
	  $n = ($n_k * $n_j)/$n_C;
	} else {
	  $n = 0;
	}
	$total += Math::Gsl::Sf::lngamma($nquote + $n);
	$total -= Math::Gsl::Sf::lngamma($nquote);
      }
    } 
    #$total += Math::Gsl::Sf::lngamma($n_C/($num_j_values*$num_k_values) + $nQuoteXYC ) * $num_j_values * $num_k_values;
    #$total -= Math::Gsl::Sf::lngamma($nQuoteXYC) * $num_j_values * $num_k_values;
  }

  #print "totally 1:$total\n";
 # $total = 0.0;
#  my ($n_j,$n_k,$n_C);
#  foreach $class_val (@class_values) {	
   
#    foreach $j_val (@j_values) {
#      $n_j = $data->getCountXClass($class_val,$j,$j_val);
#      foreach $k_val (@k_values) {
#	$n_k = $data->getCountXClass($class_val,$k,$k_val);
#	#$nquote = $prior->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
#	$nquote = $self->getNQuoteUVC($j,$k);
#	$n_C = $data->getCountClass($class_val);
#	if ($n_C > 0) {
#	  $n = ($n_k * $n_j)/$n_C;
#	} else {
#	  $n = 0;
#	}
#	$total += Math::Gsl::Sf::lngamma($nquote + $n);
#	$total -= Math::Gsl::Sf::lngamma($nquote);
#      }
#    } 
#  }
#  print "totally 2:$total\n";
  return $total;
}


sub setEquivalentSampleSizeAndInitialize {
  my ($self,$size) = @_;
  
  $self->setEquivalentSampleSize($size);
  $self->initializeSampleSize();
}

sub initializeSampleSize {
  my ($self) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();
  my $nQuoteUC = zeroes $num_atts;
  my $nQuoteUVC = zeroes $num_atts,$num_atts;
  
  my $nquote = $self->getEquivalentSampleSize();
  my $nquotec = $nquote/$class_card;
  $self->setNQuoteC($nquotec);
  
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      my $card_u = $schema->getAttributeByPos($node_u)->getType()->getCardinality();
      my $nQuoteUCVal = $nquotec/$card_u;
      #print "nQuoteUC($node_u) = $nQuoteUCVal\n";
      $nQuoteUC->set($node_u,$nQuoteUCVal);
      for (my $node_v = 0 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    # Calculate nQuoteUVC
	    my $card_v = $schema->getAttributeByPos($node_v)->getType()->getCardinality();
	    my $nQuoteUVCVal = $nQuoteUCVal/$card_v ;
	    #print "nQuoteUVC($node_u,$node_v) = $nQuoteUVCVal\n";
	    $nQuoteUVC->set($node_u,$node_v,$nQuoteUVCVal);
	  }
	}
      }
    }
  }
  $self->setInternalNQuoteUC($nQuoteUC);
  $self->setInternalNQuoteUVC($nQuoteUVC);
}

sub getNQuoteUVC {
  my ($self,$node_u,$node_v) = @_;
  
  #print "A $node_u,$node_v\n";
  
  my $ret = $self->getInternalNQuoteUVC()->at($node_u,$node_v);
  #print "OK\n";
  
  return $ret;
}

sub getNQuoteUC {
  my ($self,$node_u) = @_;
  
  return $self->getInternalNQuoteUC()->at($node_u);
}

sub getNQuoteAsteriscUVC {
  my ($self,$class_val,$node_u,$u_val,$node_v,$v_val) = @_;

  #print "$class_val,$node_u,$u_val,$node_v,$v_val\n";
  return $self->getCountingTable()->getCountXYClass($class_val,$node_u,$u_val,$node_v,$v_val) + $self->getNQuoteUVC($node_u,$node_v);
}

sub getNQuoteAsteriscUC{ 
  my ($self,$class_val,$node_u,$u_val) = @_;
  #print "$class_val,$node_u,$u_val\n";
  return $self->getCountingTable()->getCountXClass($class_val,$node_u,$u_val) + $self->getNQuoteUC($node_u);
}

sub huv {
  my ($self,$class_val,$node_u,$u_val,$node_v,$v_val) = @_;

  my $num = $self->getNQuoteAsteriscUVC($class_val,$node_u,$u_val,$node_v,$v_val);
  my $denom  = $self->getNQuoteAsteriscUC($class_val,$node_u,$u_val) * 
    $self->getNQuoteAsteriscUC($class_val,$node_v,$v_val);
  return $num / $denom;
}
1;
