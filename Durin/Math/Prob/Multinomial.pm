package Durin::Math::Prob::Multinomial;

use base Durin::Basic::MIManager;

#@ISA = (Durin::Basic::MIManager);

#use Class::MethodMaker get_set => [-java => qw/ Dimensions Cardinalities/];

use strict;
use warnings;

use PDL;

# Provides support for managing multidimensional 
# multinomial probability distributions

sub new_delta 
{
    my ($class,$self) = @_;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;

}

#NYI

sub setProbabilities {
  my ($self,$unidimensional) =@_;

  $self->{PDLTABLE} = $unidimensional->{PDLTABLE}->reshape(@{$self->getCardinalities()});
}

sub setDimensions {
  my ($self,$dims) = @_;

  $self->{DIMENSIONS} = $dims;
}

sub getDimensions {
  my ($self) = @_;

  return $self->{DIMENSIONS};
}

sub setCardinalities {
  my ($self,$cards) = @_;

  $self->{CARDINALITIES} = $cards;
  $self->{PDLTABLE} = zeroes @$cards;
}

sub getCardinalities {
  my ($self) = @_;

  return $self->{CARDINALITIES};
}

sub setTable {
  my ($self,$table) = @_;

  $self->{PDLTABLE} = $table;
  $self->prepareForSampling();
}

sub setP {
  my ($self,$pos,$val) = @_;

  set $self->{PDLTABLE},@$pos,$val;
}

sub getP {
  my ($self,$pos) = @_;
  
  return $self->{PDLTABLE}->at(@$pos);
}

sub normalize {
  my ($self) = @_;

  my $tot = $self->{PDLTABLE}->sum;
  $self->{PDLTABLE} .= $self->{PDLTABLE} * (1/$tot);

  $self->prepareForSampling();
}

sub prepareForSampling {
  my ($self) = @_;
  
   
  $self->{PROD_DIMENSIONS} = 1;
  foreach my $dim (@{$self->getCardinalities()}) {
    $self->{PROD_DIMENSIONS} *= $dim;
  }
  
  #print "PDL table: ".$self->{PDLTABLE}."\n";
  
  $self->{SAMPLING_PDLTABLE} = $self->{PDLTABLE};
  # Convert to 1-dimensional

  $self->{SAMPLING_PDLTABLE} = $self->{SAMPLING_PDLTABLE}->flat();

  # Sum
	  
  $self->{SAMPLING_PDLTABLE} = $self->{SAMPLING_PDLTABLE}->dcumusumover();
  #print "Sampling table: ".$self->{SAMPLING_PDLTABLE}."\n";
  
  # Convert to n-dimensional
  
  $self->{SAMPLING_PDLTABLE}->reshape(@{$self->getCardinalities()});
  #print "Back to n-dimensional table: ".$self->{SAMPLING_PDLTABLE}."\n";
  

  if ($self->getDimensions() == 2) {
    #print "Table: ".$self->{PDLTABLE}."\n";
    $self->{XMARGINAL} = dsumover $self->{PDLTABLE}->xchg(0,1);
    #print "X marginal: ".$self->{XMARGINAL}."\n";
    $self->{INVERSEXMARGINAL} = 1 / $self->{XMARGINAL};
    #print "Inverse X marginal: ".$self->{INVERSEXMARGINAL}."\n";
    $self->{SAMPLING_CONDITIONAL} = $self->{PDLTABLE}->copy;
    my @fixedYValueColumnList = $self->{SAMPLING_CONDITIONAL}->dog;
    foreach my $fixedYValueColumn (@fixedYValueColumnList) {
      #print "Trying to multiply : $fixedYValueColumn and ".$self->{INVERSEXMARGINAL}."\n";
      $fixedYValueColumn .= $fixedYValueColumn * $self->{INVERSEXMARGINAL};
      #print "Result : $fixedYValueColumn"
    } 
    my @fixedXValueColumnList = $self->{SAMPLING_CONDITIONAL}->xchg(0,1)->dog;
    foreach my $fixedXValueColumn (@fixedXValueColumnList) {
      $fixedXValueColumn .= $fixedXValueColumn->dcumusumover;
    }
  }
  
  if ($self->getDimensions() == 3) {
    $self->{XYMARGINAL} = dsumover $self->{PDLTABLE}->reorder(2,0,1);
    $self->{INVERSEXYMARGINAL} = 1 / $self->{XYMARGINAL};
    $self->{SAMPLING_CONDITIONAL} = $self->{PDLTABLE}->copy;
    my @fixedZValueTableList = $self->{SAMPLING_CONDITIONAL}->dog;
    foreach my $fixedZValueTable (@fixedZValueTableList) {
      #print "Trying to multiply : $fixedZValueTable and ".$self->{INVERSEXYMARGINAL}."\n";
      $fixedZValueTable .= $fixedZValueTable * $self->{INVERSEXYMARGINAL};
    }
    my @fixedXValueTableList = $self->{SAMPLING_CONDITIONAL}->reorder(2,0,1)->dog;
    foreach my $fixedXValueTable (@fixedXValueTableList) {
      my @fixedXYValueColumnList = $fixedXValueTable->dog;
      foreach my $fixedXYValueColumn (@fixedXYValueColumnList) {
	$fixedXYValueColumn .= $fixedXYValueColumn->dcumusumover;
      }
    }
  }
}

sub getCardinality {
  my ($self,$i) = @_;

  return $self->{PDLTABLE}->getdim($i);
}

sub getPYCondX {
  my ($self,$xVal,$yVal) = @_;
  
  if (!defined $self->{XMARGINAL}) {
    $self->{XMARGINAL} = dsumover $self->{PDLTABLE}->xchg(0,1);
  }
  return $self->{PDLTABLE}->at($xVal,$yVal) / $self->{XMARGINAL}->at($xVal);
}

sub getPZCondXY {
  my ($self,$xVal,$yVal,$zVal) = @_;
  
  if (!defined $self->{XYMARGINAL}) {
    $self->{XYMARGINAL} = dsumover $self->{PDLTABLE}->reorder(2,0,1);
  }
  return $self->{PDLTABLE}->at($xVal,$yVal,$zVal) / $self->{XYMARGINAL}->at($xVal,$yVal);
}

sub getMarginal {
  my ($self,$dim) = @_;
  
  my $marg = Durin::Math::Prob::Multinomial->new();
  $marg->setDimensions(1);
  $marg->setCardinalities([$self->getCardinality($dim)]);
  my $numDims = $self->getDimensions();
  my $tmp = $self->{PDLTABLE}->xchg($numDims-1,$dim);
  foreach my $i (0..$numDims-2) {
    $tmp = dsumover $tmp;
  }
  $marg->setTable($tmp);
  return $marg;
}

#sub getPYCondX {
#  my ($self,$xVal,$yVal) = @_;
  
#  if (!defined $self->{YMARGINAL}) {
#    $self->{XMARGINAL} = dsumover $self->{PDLTABLE}->xchg(0,1);
#  }
#  return $self->{PDLTABLE}->at($xVal,$yVal) / $self->{XMARGINAL}->at($xVal);
#}

#sub getPZCondXY {
#  my ($self,$xVal,$yVal,$zVal) = @_;
  
#  if (!defined $self->{XYMARGINAL}) {
#    $self->{XYMARGINAL} = dsumover $self->{PDLTABLE}->reorder(2,0,1);
#  }
#  return $self->{PDLTABLE}->at($xVal,$yVal,$zVal) / $self->{XYMARGINAL}->at($xVal,$yVal);
#}

sub sample {
  my ($self) = @_;

  return $self->sampleVector($self->{SAMPLING_PDLTABLE});
}

sub sampleYCondX {
  my ($self,$xval) = @_;
  
  if (!defined $self->{SAMPLING_PDLTABLE}) {
    $self->prepareForSampling();
  }
  
  my @l = $self->{SAMPLING_CONDITIONAL}->xchg(0,1)->dog();
  return $self->sampleVector($l[$xval])->[0];
}

sub sampleZCondXY {
  my ($self,$xval,$yval) = @_;
  
  if (!defined $self->{SAMPLING_PDLTABLE}) {
    $self->prepareForSampling();
  }
  
  my @l = $self->{SAMPLING_CONDITIONAL}->reorder(2,1,0)->dog();
  my @l2 = $l[$xval]->dog();
  return $self->sampleVector($l2[$yval])->[0];
}


sub sampleVector { 
  my ($self,$vector) = @_;
  
  #print "Sampling from vector: $vector\n";
  my $p = rand 1;
  #print "Random value: $p\n";
  my $s = where($vector,$vector > $p);
  #print "Values bigger than $p: $s\n";
  my $val_ind = $vector->nelem - $s->nelem;
  my $m_indx = $self->multidimensionalize($val_ind);

  return $m_indx;
}

sub multidimensionalize {
  my ($self,$index)  = @_;

  #print "Multidimensionalizing: $index\n";
  my $prod = $self->{PROD_DIMENSIONS};
  my $m_indx = [];
  foreach my $dim (@{$self->getCardinalities()}) {
    #print "Dim = $dim\n";
    $prod /= $dim;
    push @$m_indx,$index % $dim;
    $index = $index / $dim;
  }
  return $m_indx;
}
      
1;
