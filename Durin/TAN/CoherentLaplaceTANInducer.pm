package Durin::TAN::CoherentLaplaceTANInducer;

use Durin::Classification::Inducer;

@ISA = (Durin::Classification::Inducer);

use strict;

use Durin::TAN::TANInducer;
use Durin::ProbClassification::ProbApprox::PAFrequency;
use Durin::ProbClassification::ProbApprox::PACoherent;
use  Durin::ProbClassification::ProbApprox::PALaplace;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{INDUCER} = Durin::TAN::TANInducer->new();
    $self->setName("TAN+MS+L");
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run
{
  my ($self) = @_;
  
  my $inducer = $self->{INDUCER};
  {
    my $input = $self->{INPUT};
    $input->{TABLE} = $self->getInput()->{TABLE};
    #print $input->{TABLE}->getMetadata();
    $input->{GC}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PACoherent->new();
    $input->{TAN}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PALaplace->new();
    $inducer->setInput($input);
  }
  $inducer->run();
  my $model = $inducer->getOutput();
  $model->setName($self->getName());
  $self->setOutput($model);
}

sub getDetails {
  my ($self) = @_;
  my $details = $self->SUPER::getDetails();
  
  $details->{"Probability approximation for GC"} = "PACoherent";
  $details->{"Probability approximation for TAN"} = "PALaplace";
  my $PACoherentDetails = Durin::ProbClassification::ProbApprox::PACoherent->getDetails();
  foreach my $key (keys %$PACoherentDetails) {
    $details->{$key} = $PACoherentDetails->{$key};
  } 
 
  return $details;
}

1;
