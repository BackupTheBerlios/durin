package Durin::Classification::Experimentation::BayesModelTester;

use base Durin::Classification::Experimentation::ModelTester;

use Class::MethodMaker
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Type Sample TestingSampleSize LearningSampleSizes Runs/];

use strict;
use warnings;

use Durin::Classification::Experimentation::AUCModelApplier;

use constant Bayes => "Bayes";
use constant Sample => "Sample";

sub clear {
  my ($self) = @_;
  
  $self->setSample(undef);
}

sub init {
  my ($self,%characteristics) = @_;
  
  $self->setSample(undef);
}

sub test {
  my ($self,$model) = @_;
  
  
  # Get the sample  over which the Bayes error rate is going to be approximated
  
  if (Bayes eq $self->getType()) {
    if (!defined $self->getSample()) { 
      my $testingSet = $model->getSchema()->generateCompleteDatasetWithoutClass();
      $self->setSample($testingSet);
    }
  }
  if (!defined $self->getSample()) {
    die "No sample passed as parameter\n";
  }
  my $sample = $self->getSample();
  #my $expectedErrorRate = 0;
  #my $count = 0;
  my $applier = Durin::Classification::Experimentation::AUCModelApplier->new();
  if (Bayes eq $self->getType()) {
    $applier->setInput({TABLE => $sample, MODEL => $model, REAL_MODEL => $self->getRealModel(), BAYES => 1});
  } elsif (Sample eq $self->getType()) {
    $applier->setInput({TABLE => $sample, MODEL => $model});
  }
  $applier->run();
  return $applier->getOutput();
  #$resultTable->addResult($runId,$trainProportion,$model->getName(),$applier->getOutput());
}

sub summarize {
  my ($self,$resultTable) = @_;
  if (Bayes eq $self->getType()) {
    $resultTable->summarizeBayes();
  } else {
    $resultTable->summarize();
  }
}

sub setRealModel {
  my ($self,$model)= @_;
  
  $self->SUPER::setRealModel($model);
  $self->clear();
  my $size  = $self->getTestingSampleSize();
  #EvaluationCharacteristics()->{TESTING_SAMPLE_SIZE};
  if (Sample eq $self->getType()) {
    $self->setSample($model->generateDataset($size));    
  }
}

1;
