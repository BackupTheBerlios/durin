# TAN inducer with Laplace estimates

package Durin::TAN::LaplaceTANInducer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::TAN::TANInducer;
use Durin::ProbClassification::ProbApprox::PALaplace;

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
      $input->{TAN}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PALaplace->new();
      $input->{GC}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PALaplace->new();
      $inducer->setInput($input);
    }
    $inducer->run();
    $self->setOutput($inducer->getOutput());
  }

1;
