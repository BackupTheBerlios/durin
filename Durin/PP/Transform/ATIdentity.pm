package Durin::PP::Transform::ATIdentity;

use Durin::PP::Transform::AttributeTransform;

@ISA = (Durin::PP::Transform::AttributeTransform);

use strict;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub transform
  {
    my ($self,$value) = @_;

    return $value;
  }

1;
