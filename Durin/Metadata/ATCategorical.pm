package Durin::Metadata::ATCategorical;

use Durin::Metadata::AttributeType

@ISA = (Durin::Metadata::AttributeType);

use strict;

#sub new 
#{
#    my $proto = shift;
#    my $class = ref($proto) || $proto;
#    my $self = Durin::Metadata::AttributeType->new();
#   
#    $self->{LIST_OF_VALUES} = [];
#    $self->setName("Categorical");
#    
#    bless ($self,$class);
#    return $self;
#}

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{LIST_OF_VALUES} = [];
    $self->setName("Categorical");    
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
    
    $self->setValues(\@{$source->getValues()});
}

sub isCategorical
  {
    my ($class,$att) = @_;
    
    return ($att->getTypeName() eq "Categorical");
  }

sub setValues($$)
{
    my ($self,$values) = @_;
    
    $self->{LIST_OF_VALUES} = $values;
}

sub getValues($)
{
    my $self = shift;
    
    return $self->{LIST_OF_VALUES};
}

sub getCardinality($)
{
    my $self = shift;
    
    return $#{$self->{LIST_OF_VALUES}} + 1;
}

sub setRest($$)
{
    my ($self,$rest) = @_;

#    print "rest is $rest\n";
    my @ref = split(/:/,$rest);
    $self->setValues(\@ref);
}

sub getRest($)
{ 
    my $self = shift;
    
    return join(':',@{$self->getValues()});
}

1;
