package Durin::PP::Transform::ATValueMap;

use Durin::PP::Transform::AttributeTransform;

@ISA = (Durin::PP::Transform::AttributeTransform);

use strict;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
    $self->{MAP} = undef;
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
    die " Durin::PP::Transform::ATValueMap::clone\n";
}

sub setValueMap
  {
    my ($self,$map) = @_;
    
    $self->{MAP} = $map;
  }

sub transform
  {
    my ($self,$value) = @_;

    return $self->{MAP}->{$value};
  }

1;
