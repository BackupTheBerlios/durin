package Durin::Metadata::ATString;

use Durin::Metadata::AttributeType;

@ISA = (Durin::Metadata::AttributeType);

use strict;

use Durin::Metadata::AttributeType;

#sub new 
#{
#    my $proto = shift;
#    my $class = ref($proto) || $proto;
#    my $self = Durin::Metadata::AttributeType->new();
#   
#    $self->setName("String");
#
#    bless ($self,$class);
#    return $self;
#}

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("String");    
}

1;
