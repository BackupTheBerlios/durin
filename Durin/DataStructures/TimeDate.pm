package Durin::DataStructures::TimeDate;

use Durin::FlexibleIO::Externalizable;

@ISA = (Durin::FlexibleIO::Externalizable);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;
   
    $self->{TIME} = 0;
  }

#sub clone_delta
#  { 
#    my ($class,$self,$source) = @_;
#  }

sub setTime
  {
    my ($self,$seconds) = @_;
    
    $self->{TIME} = $seconds;
  }

sub getTime
  {
    my ($self) = @_;
    
    return $self->{TIME};
  }
