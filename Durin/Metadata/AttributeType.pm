package Durin::Metadata::AttributeType;

use Durin::Components::Metadata;

@ISA = (Durin::Components::Metadata);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{UNKNOWNS} = undef;   
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    $self->setHasUnknowns($source->getHasUnknowns());
  }

#sub new
#{
#    my $self = {};
#    bless $self;
#    $self->{TYPE_NAME} = "";
#    
#    return $self;
#}

#sub initialize($$)
#{
#    my ($self,$source) = @_;
#    
#    $self->SUPER::initialize($source);
#    $self->setName($source->getName());
#    $self->setRest($source->getRest());
#}

#sub setName($$)
#{
#    my ($self,$type) = @_;
#    
#    $self->{TYPE_NAME} = $type;
#}

#sub getName($)
#{
#    my $self = shift;
#    
#    return $self->{TYPE_NAME};
#}

sub isUnknown
  { 
    my ($self,$value) = @_;
      
    return ($value eq $self->unknownValue());
  }

sub unknownValue
  {
    my ($self) = @_;

    return "?";
  }

sub setHasUnknowns
  {
    my ($self,$value) = @_;
    
    $self->{UNKNOWNS} = $value;
  }

sub getHasUnknowns
  {
    my ($self) = @_;
    
    return $self->{UNKNOWNS};
  }

sub setRest
  {
    my ($self,$rest) = @_;
  }

sub getRest
  {
    my ($self) = @_;
    
    return "";
  }

# converts an object into a string for serialization

sub makestring
  {
    my ($self,$value) = @_;
    
    return $value;
  }

# converts a string into an object for deserialization

sub makeobject
  {
    my ($self,$string) = @_;
    
    return $string;
  }


1;
