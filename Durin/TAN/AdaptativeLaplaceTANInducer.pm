package Durin::TAN::AdaptativeLaplaceTANInducer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::TAN::TANInducer;
use Durin::ProbClassification::ProbApprox::PAFrequency;
use Durin::ProbClassification::ProbApprox::PALaplace;
use Durin::ProbClassification::ProbApprox::PAAdaptativeLaplace;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{INDUCER} = Durin::TAN::TANInducer->new();
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
    print $input->{TABLE}->getMetadata();
    $input->{GC}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PAAdaptativeLaplace->new();
    $input->{TAN}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PALaplace->new();
    $inducer->setInput($input);
  }
  $inducer->run();
  $self->setOutput($inducer->getOutput());
}

1;
