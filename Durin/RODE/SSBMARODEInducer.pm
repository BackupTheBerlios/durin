# BMA Restricted One Dependence Estimator Inducer

package Durin::RODE::SSBMARODEInducer;

use Durin::Classification::Inducer;

use base "Durin::RODE::ODEInducer";
use PDL;

use strict;
use warnings;

use Durin::RODE::RODEDecomposable;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("SSBMARODE");
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub getStubbornness {
  return Durin::RODE::RODEDecomposable::ParameterizedStubbornness;
}

sub getParameterizedStubbornnessFactor {
  return 0.95;
}

1;
