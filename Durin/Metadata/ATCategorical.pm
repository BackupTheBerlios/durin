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
    $self->{HASH_OF_VALUES} = {};
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
    $self->{HASH_OF_VALUES} = {};
    my $i = 0;
    foreach my $val (@$values) {
      $self->{HASH_OF_VALUES}{$val} = $i;
      $i++;
    }
}
sub getValue($$) {
  my ($self,$pos)  = @_;

  return $self->{LIST_OF_VALUES}[$pos];
}

sub getValues($)
{
    my $self = shift;
    
    return $self->{LIST_OF_VALUES};
}

# Returns the position of a value of the attribute in the list

sub getValuePosition($$) {
  my ($self,$val) = @_;

  return $self->{HASH_OF_VALUES}{$val};
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
