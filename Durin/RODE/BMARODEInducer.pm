# BMA Restricted One Dependence Estimator Inducer

package Durin::RODE::BMARODEInducer;

use Durin::Classification::Inducer;

use base "Durin::RODE::ODEInducer";
use PDL;

use strict;
use warnings;

use Durin::RODE::RODEDecomposable;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("BMARODE");
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub getStubbornness {
  return Durin::RODE::RODEDecomposable::NoStubbornness;
}

1;
