package Durin::Metadata::Attribute;

use Durin::Components::Metadata;

@ISA = (Durin::Components::Metadata);

use strict;

use Durin::Metadata::AttributeType;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{TYPE} = undef;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
    
    $self->setType($source->getType()->clone());
}

#sub initialize($$)
#{
#    my ($self,$source) = @_;
#    
#    $self->SUPER::initialize($source);#
#
#    my ($attType) = $source->getType();
#    $self->setType($attType->clone());
#}

sub setType($$)
{
    my ($self,$type) = @_;
    
    $self->{TYPE} = $type;
}

sub getType($)
{
    my $self = shift;
    
    return $self->{TYPE};
}

sub getTypeName($)
{
    my $self = shift;
    
    return $self->getType()->getName();
}

sub isUnknown
  {
    my ($self,$value) = @_;
    
    return $self->{TYPE}->isUnknown($value);
  }

sub makestring($)
{
    my $self = shift;

    return "[ Name: ".$self->getName().", TypeName: ".$self->getTypeName()."]";
}

1;
