package Durin::ProbClassification::ProbApprox::PATANModel;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;

    $self->{DISTRIBS} = {};
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::ProbApprox::PAFG clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub setDistribution
  {
    my ($self,$node,$distrib) = @_;

    $self->{DISTRIBS}{$node} = $distrib;
  }

sub getDistribution
  {
    my ($self,$node) = @_;

    return $self->{DISTRIBS}{$node};
  }

sub setSchema
  {
    my ($self,$schema) = @_;
    
    $self->{SCHEMA} = $schema;
  }

sub getSchema
  {
    my ($self) = @_;
    
    return $self->{SCHEMA};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;

    my $classPos = $self->{SCHEMA}->getClassPos();
    my $classAttType = $self->{SCHEMA}->getAttributeByPos($classPos)->getType();
    my $classValIndex = $classAttType->getValuePosition($classVal);

    return $self->{DISTRIBS}{$classPos}->getP([$classValIndex]);
  }
   
sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;

    my $classPos = $self->{SCHEMA}->getClassPos();
    my $classAttType = $self->{SCHEMA}->getAttributeByPos($classPos)->getType();
    my $classValIndex = $classAttType->getValuePosition($classVal);
    my $attXType = $self->{SCHEMA}->getAttributeByPos($attX)->getType();
    my $attXValIndex = $attXType->getValuePosition($attXVal);
      
    return $self->{DISTRIBS}{$attX}->getPYCondX($classValIndex,$attXValIndex);
  }

sub getPYCondXClass
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
    
    my $classPos = $self->{SCHEMA}->getClassPos();
    my $classAttType = $self->{SCHEMA}->getAttributeByPos($classPos)->getType();
    my $classValIndex = $classAttType->getValuePosition($classVal);
    my $attXType = $self->{SCHEMA}->getAttributeByPos($attX)->getType();
    my $attXValIndex = $attXType->getValuePosition($attXVal);
    my $attYType = $self->{SCHEMA}->getAttributeByPos($attY)->getType();
    my $attYValIndex = $attYType->getValuePosition($attYVal);
    
    return $self->{DISTRIBS}{$attY}->getPZCondXY($classValIndex,$attXValIndex,$attYValIndex);
  }

sub getMarginalDistribution {
  my ($self,$node) = @_;
  
  #print "Marginalizing $node\n";
  my $dim = $self->{DISTRIBS}{$node}->getDimensions()-1;
  #print "Marginalizing $node\n";
  return $self->{DISTRIBS}{$node}->getMarginal($dim);
}

sub getDetails()
  {
    my ($class) = @_;
    
    return {};
  }

sub sampleClass {
  my ($self) = @_;

  my $classPos = $self->{SCHEMA}->getClassPos();
  my $classAttType = $self->{SCHEMA}->getAttributeByPos($classPos)->getType();
  my $classValIndx = $self->{DISTRIBS}{$classPos}->sample()->[0];
  return $classAttType->getValue($classValIndx);
}

sub sampleXCondClass {
  my ($self,$classVal,$attXIndx) = @_;
  
  my $classPos = $self->{SCHEMA}->getClassPos(); 
  my $classAttType = $self->{SCHEMA}->getAttributeByPos($classPos)->getType(); 
  my $classValIndx = $classAttType->getValuePosition($classVal);
  my $attXType = $self->{SCHEMA}->getAttributeByPos($attXIndx)->getType();
  my $attXValIndx = $self->{DISTRIBS}{$attXIndx}->sampleYCondX($classValIndx);
  return  $attXType->getValue($attXValIndx);
}

sub sampleYCondXClass {
  my ($self,$classVal,$attXIndx,$attXVal,$attYIndx) = @_;
  
  my $classPos = $self->{SCHEMA}->getClassPos(); 
  my $classAttType = $self->{SCHEMA}->getAttributeByPos($classPos)->getType(); 
  my $classValIndx = $classAttType->getValuePosition($classVal);
  my $attXType = $self->{SCHEMA}->getAttributeByPos($attXIndx)->getType();
  my $attXValIndx = $attXType->getValuePosition($attXVal);
  my $attYType = $self->{SCHEMA}->getAttributeByPos($attYIndx)->getType();
  my $attYValIndx = $self->{DISTRIBS}{$attYIndx}->sampleZCondXY($classValIndx,$attXValIndx);
  return  $attYType->getValue($attYValIndx);
}
