package Durin::Metadata::ATUnknown;

use base Durin::Metadata::AttributeType;

#@ISA = (Durin::Metadata::AttributeType);

use strict;

#sub new 
#{
#    my $proto = shift;
#    my $class = ref($proto) || $proto;
#    my $self = Durin::Metadata::AttributeType->new();
#   
#    $self->setName("Unknown");
#
#    bless ($self,$class);
#    return $self;
#}

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("Unknown");    
}

1;
