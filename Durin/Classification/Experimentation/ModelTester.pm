package Durin::Classification::Experimentation::ModelTester;

use Class::MethodMaker get_set => [-java => qw/ RealModel /];

use strict;
use warnings;

sub test($$)
  { die "Pure Virtual\n";}

sub init {}

1;
