package Durin::ProbClassification::ProbApprox::PACoherent;

use strict;
use warnings;

use base 'Durin::Classification::Model';

use Class::MethodMaker
  get_set => [ -java => qw/EquivalentSampleSize InternalNQuoteUC InternalNQuoteUVC NQuoteC Schema/];
use PDL;

sub new_delta {
  my ($class,$self) = @_;
  
  $self->{COUNTTABLE} = undef; 
  #$self->{DATASETSIZE} = $self->getLambda();
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
  
  die "Durin::ProbClassification::ProbApprox::PACoherent clone not implemented";
}

sub getLambda {
  return 100;
}

sub setCountTable {
  my ($self,$ct) = @_;
  
  $self->{COUNTTABLE} = $ct;
}

sub getCountTable {
  my ($self) = @_;
  
  return $self->{COUNTTABLE};
}

sub getPClass {
  my ($self,$classVal) = @_;
  
  my $num = $self->{COUNTTABLE}->getCountClass($classVal) + $self->getNQuoteC();
  my $denom = $self->{COUNTTABLE}->getCount() + $self->getEquivalentSampleSize();
  return $num/$denom;
}

sub getPXYClass {
  my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
  
  my $CXYClass;
  if ($attX > $attY) {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
  } else {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
  }
  my $num = $CXYClass + $self->getNQuoteUVC($attX,$attY);
  my $denom = $self->{COUNTTABLE}->getCount() + $self->getEquivalentSampleSize();
  return $num / $denom;
}

sub getPClassCondX {
  my ($self,$classVal,$attX,$attXVal) = @_;
  
  my $num =  $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $self->getNQuoteUC($attX);
  my $nquoteu = $self->getEquivalentSampleSize() / $self->{COUNTTABLE}->getNumAttValues($attX);
  my $denom = $self->{COUNTTABLE}->getCountX($attX,$attXVal) +  $nquoteu;
  
  return $num / $denom;
}


sub getPClassCondXY {
  my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
  
  my $CXYClass;
  
  if ($attX > $attY) {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
    # print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
  } else {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
    # print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
  }
  
  my $cardXY = $self->{COUNTTABLE}->getNumAttValues($attY) * $self->{COUNTTABLE}->getNumAttValues($attX);
  my $num = $CXYClass +  $self->getNQuoteUVC($attX,$attY);
  my $denom = $self->{COUNTTABLE}->getCountXY($attX,$attXVal,$attY,$attYVal) +  ($self->getEquivalentSampleSize() / $cardXY);
  return $num / $denom;
}

sub getPXCondClass {
  my ($self,$classVal,$attX,$attXVal) = @_;
  
  my $num = $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $self->getNQuoteUC($attX);
  my $denom = $self->{COUNTTABLE}->getCountClass($classVal) + $self->getNQuoteC();
  return $num / $denom;
}

sub getPYCondXClass {
  my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
  
  my $CXYClass;
  
  if ($attX > $attY) {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
    # print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
  } else {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
    # print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
  }
  
  my $num = $CXYClass + $self->getNQuoteUVC($attX,$attY);
  my $denom = $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $self->getNQuoteUC($attX);
  return $num / $denom;
}

sub getSinergy {
  my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
  
  my $CXYClass;
  
  if ($attX > $attY) {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
  } else {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
  }
  
  my $num = ($CXYClass +  $self->getNQuoteUVC($attX,$attY)) * ($self->{COUNTTABLE}->getCountClass($classVal) +  $self->getNQuoteC());
  my $denom =  ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $self->getNQuoteUC($attX)) 
    * ($self->{COUNTTABLE}->getCountXClass($classVal,$attY,$attYVal) + $self->getNQuoteUC($attY));
  return $num / $denom;
}

sub getDetails()
  {
    my ($class) = @_;
    
    return {"PACoherent softening constant"=> $class->getLambda()};
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
  #  print "s1 = $self.\n";
}

sub getNQuoteUVC {
  my ($self,$node_u,$node_v) = @_;
  #print "s2 = $self.\n";
  #print "Node u : $node_u Node v: $node_v\n";
  #print $self->getInternalNQuoteUVC();
  return $self->getInternalNQuoteUVC()->at($node_u,$node_v);
}

sub getNQuoteUC {
  my ($self,$node_u) = @_;
  #print "Node u : $node_u\n";
  return $self->getInternalNQuoteUC()->at($node_u);
}


1;
