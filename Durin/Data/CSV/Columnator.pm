package Durin::Data::CSV::Columnator;

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

use strict;

# Converts an array into a string

sub ToString
  {
    my ($self,$array) = @_; 

    die "Pure virtual\n";
  }

# Converts a string into an array

sub ToArray
  {
    my ($self,$string) = @_;

    die "Pure virtual\n";
  }
