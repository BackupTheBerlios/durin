package Durin::ProbClassification::BayesErrorRateCalculator;

#use Class::MethodMaker get_set => [-java => qw/ Schema MultinomialGenerator IndepSet ProbApprox Tree TAN/];

use strict;
use warnings;

#use Durin::ModelGeneration::ModelGenerator;
#use Durin::TAN::TAN;
#use Durin::Math::Prob::MultinomialGenerator;
#use Durin::ProbClassification::ProbApprox::PATANModel;
#use Durin::Classification::ClassedTableSchema;
#use Durin::Metadata::Attribute;
#use Durin::Metadata::AttributeType;
#use Durin::Metadata::ATCreator;
#use Durin::DataStructures::Graph;

#use POSIX;

@Durin::ProbClassification::BayesErrorRateCalculator::ISA = qw(Durin::Components::Process);

sub new_delta {
  my ($class,$self) = @_;

}

sub clone_delta {
  my ($class,$self,$source) = @_;
  
  die "Durin::TAN::RandomTANGenerator clone not implemented";
}

sub run($)
{
  my ($self) = @_;
  
  my $input = $self->getInput();
  
  # Get the real model
  
  $self->{REAL_MODEL} = $input->{REAL_MODEL};
  
  # Get the induced model

  $self->{INDUCED_MODEL} = $input->{INDUCED_MODEL};
  
  # Get the sample  over which the Bayes error rate is going to be approximated
  #if (defined $input->{SAMPLE}) {
    $self->{SAMPLE} = $input->{SAMPLE};
  #} else {
    # Get the sample size over which the Bayes error rate is going to be approximated
  #  if (defined $input->{SAMPLE_SIZE}) {
  #    $self->{SAMPLE_SIZE} = $input->{SAMPLE_SIZE};
  #
  #    my $sample = generateDataset($self->{SAMPLE_SIZE});
  #  }
  #}
  
  # Get the percentage of independent tables 
  my $expectedErrorRate = 0;
  my $count = 0;
  $self->{SAMPLE}->open();
  $self->{SAMPLE}->applyFunction(sub {
				   my ($row) = @_;
				   
				   my $predictedClass = $self->{INDUCED_MODEL}->classify($row);
				   my $realDistrib = $self->{REAL_MODEL}->predict($row)->[0];
				   my $expectedError = 1 -  $realDistrib->{$predictedClass};
				   #print "Predicted: $predictedClass Error expected:$expectedError\n";
				   
				   $count++;
				   $expectedErrorRate += $expectedError;
				 });
  $expectedErrorRate /= $count;
  $self->{SAMPLE}->close();

  $self->setOutput({ERROR_RATE => $expectedErrorRate});
}
