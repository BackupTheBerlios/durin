package Durin::Data::CSV::CSVColumnator;

use Durin::Data::CSV::Columnator;

@ISA = (Durin::Data::CSV::Columnator);

use strict;

# Converts an array into a string

sub ToString
  {
    my ($self,$array) = @_;

    return join(',',@$array);
  }

# Converts a string into an array

sub ToArray
  {
    my ($self,$string) = @_;
    
    #print "String: $string\n";
    my @a = split(/,/,$string);
    #print "Array: @a\n";
    return \@a;
  }
