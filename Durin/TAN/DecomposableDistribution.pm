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

sub getLambda {
  return 10;
}

sub calculateDecomposableInf {
  my ($self,$j,$k,$class_att,$schema,$data) = @_;
  
  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  my ($Pxyz,$Pz,$Pxz,$Pyz,$quotient,$temp,$infoTotal,$infoPartial);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  my $total = 0.0;
  my ($nquote,$n);
  
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
