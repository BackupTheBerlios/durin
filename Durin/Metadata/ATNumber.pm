package Durin::Metadata::ATNumber;

use base Durin::Metadata::AttributeType;

#ISA = (Durin::Metadata::AttributeType);

use strict;

#sub new 
#{
#    my $proto = shift;
#    my $class = ref($proto) || $proto;
#    my $self = Durin::Metadata::AttributeType->new();
#   
#    $self->setName("Number");
#
#    bless ($self,$class);
#    return $self;
#}

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->setName("Number");    
  }

sub isNumber
  {
    my ($class,$att) = @_;
    
    return ($att->getTypeName() eq "Number");
  }

sub setRest
  {
    my ($self,$rest) = @_;
    
    $self->setHasUnknowns($rest eq $self->unknownValue());
  }

sub getRest
  {
    my ($self) = @_;
    
    if ($self->getHasUnknowns())
      {
	return $self->unknownValue();
      }
    else
      {
	return "";
      }
  }
1;
