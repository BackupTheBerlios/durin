# TAN inducer as described by Friedman and Goldszmidt

package Durin::TAN::FGGTANInducer;

use Durin::Classification::Inducer;

@ISA = (Durin::Classification::Inducer);

use strict;
use Durin::TAN::TANInducer;
use Durin::ProbClassification::ProbApprox::PAFrequency;
use Durin::ProbClassification::ProbApprox::PAFG;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{INDUCER} = Durin::TAN::TANInducer->new();
    $self->setName("sTAN");
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
    $input->{GC}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PAFrequency->new();
    $input->{TAN}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PAFG->new();
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
  
  $details->{"Probability approximation for GC"} = "PAFrequency";
  $details->{"Probability approximation for TAN"} = "PAFG";
  my $PAFGDetails = Durin::ProbClassification::ProbApprox::PAFG->getDetails();
  foreach my $key (keys %$PAFGDetails) {
    $details->{$key} = $PAFGDetails->{$key};
  }
  return $details;
}
    

1;
