package Durin::Classification::Experimentation::ModelTesterFactory;

use strict;
use warnings;

use Durin::Classification::Experimentation::BayesModelTester;

sub create {
  my ($class,$evaluationCharacteristics) = @_;
  
  my $name = $evaluationCharacteristics->{Type};
  my $tester;
  if ("Bayes" eq $name) {
    $tester = Durin::Classification::Experimentation::BayesModelTester->new(%$evaluationCharacteristics);
  } elsif ("Sample" eq $name) {
    $tester = Durin::Classification::Experimentation::BayesModelTester->new(%$evaluationCharacteristics);
  }
  #$tester->setEvaluationCharacteristics($evaluationCharacteristics);
  #$tester->init($evaluationCharacteristics);
  return $tester;
}

1;
