package Durin::Classification::CompositeInducer;

use strict;
use warnings;

@Durin::Classification::CompositeInducer::ISA = qw(Durin::Classification::Inducer);

sub new_delta {
  my ($class,$self) = @_;
  
  $self->{INDUCER_LIST} = [];
}

sub clone_delta {
  my ($class,$self,$source) = @_;
}

sub addInducer {
  my ($self,$inducer) = @_;

  push @{$self->{INDUCER_LIST}},$inducer;
}

sub getInducerList($) {
  my ($self) = @_;
  
  return $self->{INDUCER_LIST};
}

sub setPreviousToLearningHook($$) {
  my ($self,$hookFunction) = @_;
  
  $self->{PREVIOUS_HOOK} = $hookFunction;
}

sub setPosteriorToLearningHook($$) {
  my ($self,$hookFunction) = @_;
  
  $self->{POSTERIOR_HOOK} = $hookFunction;
}
		
sub previousToLearningHook($$) { 
  my ($self,$inducer) = @_;
  
  if (defined $self->{PREVIOUS_HOOK}){
    &{$self->{PREVIOUS_HOOK}}($inducer);
  }
}

sub posteriorToLearningHook($$) {
  my ($self,$inducer) = @_;
  
  if (defined $self->{POSTERIOR_HOOK}){
    &{$self->{POSTERIOR_HOOK}}($inducer);
  }
}


sub run($) {
  my ($self) = @_;
  my $input = $self->getInput();
  
  # We have to run a bunch of classifiers over the same dataset.
  # setting the SHARECOUNTTABLE to true allows for the count table
  # to be generated only once and be shared by the different classifiers.

  my $modelList = [];
  my $sharedCountTable;
  #print "LEts see\n";
  #if ($input->{SHARE_COUNT_TABLE}) {
  #  print "Sharing count tables, I already told you!!!\n";
  #}

  foreach my $inducer (@{$self->{INDUCER_LIST}}) {
    $self->previousToLearningHook($inducer);
    $inducer->setInput($input);
    if ($input->{SHARE_COUNT_TABLE} && defined($sharedCountTable)) {
      $input->{COUNTING_TABLE} = $sharedCountTable;
    }
    my $model = $inducer->run();
    if ($input->{SHARE_COUNT_TABLE} && !defined($sharedCountTable)) {
      $sharedCountTable = $inducer->getCountingTable();
    }
    $self->posteriorToLearningHook($inducer);
    push @$modelList,$model;
  }
  $self->setOutput({MODEL_LIST => $modelList});
}
	
# Returns a hash with inducer details
sub getDetails($) {
  my ($class) = @_;

  my $details = {}; 
  return $details;
}

1;
