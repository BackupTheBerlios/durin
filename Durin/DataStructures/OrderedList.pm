package Durin::DataStructures::OrderedList;

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{LIST} = [];
}

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    my (@List,$e);
    
    foreach $e (@{$source->getElements()})
      {
	$self->add($e);
      }
    #    print "DataStructures::UGraph cloning not tested\n");
  }

sub add
  {
    my ($self,$weight,$element) = @_;
    
    $i = 0;
    while (($i < $self->getLength()) && ($weight < $self->{LIST}[$i][0]))
      {
	$i++;
      }
    splice @{$self->{LIST}},$i,0,[$weight,$element];
  }

sub getFirst
  {
    my ($self) = @_;

    return shift @{$self->getElements()}
  }

sub getElements
  {
    my ($self) = @_;

    return $self->{LIST};
  }

sub getLength
  {
    my ($self) = @_;

    return scalar(@{$self->{LIST}});
  }

sub isEmpty
  {
    my ($self) = @_;
    
    #print "Length of P: ",$self->getLength(),"\n";

    return ($self->getLength() == 0);
  }
1;
