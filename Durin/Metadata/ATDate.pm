package Durin::Metadata::ATDate;

use Durin::Metadata::AttributeType;

@ISA = (Durin::Metadata::AttributeType);

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
    
    $self->setName("Date");    
  }

sub isDate
  {
    my ($class,$att) = @_;
    
    return ($att->getTypeName() eq "Date");
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
