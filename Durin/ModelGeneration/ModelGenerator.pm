package Durin::ModelGeneration::ModelGenerator;

use Durin::Components::Process;
use Durin::Basic::NamedObject;

@ISA = qw(Durin::Components::Process Durin::Basic::NamedObject);

# This is the base class for model generators.
# Model generators are processes that randomly
# generate models for the data. After the generation,
# these models will be used to generate the datasets 
# over which the learning will be performed.

# A model generator receives (at least):
#
# NUMBER_OF_MODELS -> Number of models
#
# and returns
#
# LIST_OF_MODELS -> list of models generated.


use strict;

sub new_delta {
  my ($class,$self) = @_;
  
  $self->{NUMBER_OF_MODELS} = 1; # By default generate 1 model.
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub run($)
{
  die "Pure virtual Durin::ModelGeneration::ModelGenerator::run\n";
}

# Returns a hash with model generator details
sub getDetails($) {
  my ($class) = @_;

  my $details = {}; 
  return $details;
}
	       
1;
