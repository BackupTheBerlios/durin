package Durin::Classification::Experimentation::ModelTester;

use base Durin::Components::Process;
use Class::MethodMaker get_set => [-java => qw/ RealModel EvaluationCharacteristics/];

use strict;
use warnings;

use Durin::Classification::Experimentation::BayesModelTester;

sub new_delta
  {
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub create {
  my ($class,$evaluationCharacteristics) = @_;
  
  my $name = $evaluationCharacteristics->{METHOD_NAME};
  my $tester;
  if ("Bayes" eq $name) {
    $tester = Durin::Classification::Experimentation::BayesModelTester->new();
  } elsif ("Sample" eq $name) {
    $tester = Durin::Classification::Experimentation::BayesModelTester->new();
  }
  $tester->setEvaluationCharacteristics($evaluationCharacteristics);
  $tester->init($evaluationCharacteristics);
  return $tester;
}

sub test($$)
  { die "Pure Virtual\n";}

sub init {}

1;
