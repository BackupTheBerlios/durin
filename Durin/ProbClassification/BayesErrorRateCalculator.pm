############################################################
# OUTDATED!!! Are you sure you want to use it???? Try 
# Durin::Classification::Experimentation::BayesModelTester;

pppp

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

  if (defined $input->{RANDOM_SAMPLE}){
    $self->{RANDOM_SAMPLE} = $input->{RANDOM_SAMPLE};
  } else {
    $self->{RANDOM_SAMPLE} = 0;
  }
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
				   #print "Classifying: ".join(',',@$row)."\n";
				   my $predictedClass = $self->{INDUCED_MODEL}->classify($row);
				   my $predictionArray = $self->{REAL_MODEL}->predict($row);
				   #my ($condDistrib,$class,$distrib,$total) = $self->{REAL_MODEL}->predict($row);
				   my $expectedError;
				   if ($self->{RANDOM_SAMPLE}) {
				     $expectedError = 1 - $predictionArray->[0]->{$predictedClass};
				   } else {
				     $expectedError = $predictionArray->[3] *
				       (1 -  $predictionArray->[0]->{$predictedClass});
				   }
				   #print "Predicted: $predictedClass Error expected:$expectedError\n";
				   $count++;
				   $expectedErrorRate += $expectedError;
				 });
  if ($self->{RANDOM_SAMPLE}) {
    $expectedErrorRate /= $count;
  }
  $self->{SAMPLE}->close();
  
  $self->setOutput({ERROR_RATE => $expectedErrorRate});
}
