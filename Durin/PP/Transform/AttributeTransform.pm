package Durin::PP::Transform::AttributeTransform;

# This is the base class for any attribute transform

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

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

    die "Pure virtual";
  }

1;
