package Durin::Math::Prob::MultinomialGenerator;

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

use Durin::Math::Prob::Multinomial;

use strict;
use warnings;

sub new_delta {
    my ($class,$self) = @_;
}

sub clone_delta {
    my ($class,$self,$source) = @_;
}
# Generates an unconstrained multinomial

sub generateMultidimensionalMultinomial {
  my ($self,$dimList) = @_;

  my $numDims = scalar @$dimList;
  my $m = Durin::Math::Prob::Multinomial->new();
  $m->setDimensions($numDims);
  $m->setCardinalities($dimList);
  
  my $totalCard = 1;
  foreach my $dim (@$dimList)
    {
      $totalCard *= $dim;
    }
  
  # Generate multinomial

  my $unidimensional = $self->generateUnidimensionalMultinomial($totalCard);
  $m->setProbabilities($unidimensional);
  $m->normalize();
  return $m;
}

# Generates a unidimensional multinomial following a 
# Dirichlet with uniform weigths

sub generateUnidimensionalMultinomial {
  my ($self,$dim) = @_;
  
  # Generate p_i's
  my $m = Durin::Math::Prob::Multinomial->new();
  $m->setDimensions(1);
  $m->setCardinalities([$dim]);
  
  foreach my $i (0..$dim-1) {
    $m->setP([$i],-log(rand 1));
  }
  $m->normalize();

  return $m;
}

sub generateIndependentBidimensionalMultinomial {
  my ($self,$distribX,$distribY) = @_;

  my $cardX = $distribX->getCardinality(0);
  my $cardY = $distribY->getCardinality(0); 
  
  my $m = Durin::Math::Prob::Multinomial->new();
  $m->setDimensions(2);
  $m->setCardinalities([$cardX,$cardY]);
  
  foreach my $i (0..$cardX-1) {
    foreach my $j (0..$cardY-1) {
      $m->setP([$i,$j],$distribX->getP([$i])*$distribY->getP([$j]));
    }
  }
  return $m;
}

sub generateDependentBidimensionalMultinomial {
  my ($self,$distribX,$cardY) = @_;

  my $cardX = $distribX->getCardinality(0);
  
  my $m = Durin::Math::Prob::Multinomial->new();
  $m->setDimensions(2);
  $m->setCardinalities([$cardX,$cardY]);

  my $distribYCondX;
  foreach my $i (0..$cardX-1) {
    $distribYCondX = $self->generateUnidimensionalMultinomial($cardY);
    foreach my $j (0..$cardY-1) {
      $m->setP([$i,$j],$distribX->getP([$i])*$distribYCondX->getP([$j]));
    }
  }
  return $m;
}

sub generateIndependentTridimensionalMultinomial {
  my ($self,$distribX,$distribY,$distribZ) = @_;

  my $cardX = $distribX->getCardinality(0);
  my $cardY = $distribY->getCardinality(0); 
  my $cardZ = $distribZ->getCardinality(0); 
  
  my $m = Durin::Math::Prob::Multinomial->new();
  $m->setDimensions(3);
  $m->setCardinalities([$cardX,$cardY,$cardZ]);
  
  foreach my $i (0..$cardX-1) {
    foreach my $j (0..$cardY-1) {
      foreach my $k (0..$cardZ-1) {
	$m->setP([$i,$j,$k],$distribX->getP([$i])*$distribY->getP([$j])*$distribZ->getP([$k]));
      }
    }
  }
  return $m;
}

sub generateDependentTridimensionalMultinomial {
  my ($self,$distribX,$distribY,$cardZ) = @_;

  my $cardX = $distribX->getCardinality(0);
  my $cardY = $distribY->getCardinality(0);
  
  my $m = Durin::Math::Prob::Multinomial->new();
  $m->setDimensions(3);
  $m->setCardinalities([$cardX,$cardY,$cardZ]);

  my $distribZCondXY;
  foreach my $i (0..$cardX-1) {
    foreach my $j (0..$cardY-1) {
      $distribZCondXY = $self->generateUnidimensionalMultinomial($cardZ);
      foreach my $k (0..$cardZ-1) {
	$m->setP([$i,$j,$k],$distribX->getP([$i])*$distribY->getP([$j])*$distribZCondXY->getP([$k]));
      }
    }
  }
  return $m;
}

# Not Yet Implemented
sub generateConstrainedMultinomial { 
  my ($self,$numDims,$marginalList) = @_;
}

1;
