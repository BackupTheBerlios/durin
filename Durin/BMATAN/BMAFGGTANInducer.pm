# TAN inducer as described by Friedman and Goldszmidt but with Bayesian Model Averaging

package Durin::BMATAN::BMAFGGTANInducer;

use Durin::Classification::Inducer;

@ISA = (Durin::Classification::Inducer);

use strict;

use Durin::BMATAN::BMATANInducer;
use Durin::ProbClassification::ProbApprox::PAFrequency;
use Durin::ProbClassification::ProbApprox::PAFG;
use Durin::BMATAN::MultipleTANGenerator;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{INDUCER} = Durin::BMATAN::BMATANInducer->new();
    $self->setName("sTAN+BMA");
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
    #print $input->{TABLE}->getMetadata(),"\n";
    $input->{GC}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PAFrequency->new();
    $input->{TAN}->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PAFG->new();
    $input->{MTANG} = Durin::BMATAN::MultipleTANGenerator->new();
    $inducer->setInput($input);
  }
  $inducer->run();
  my $BMAModel = $inducer->getOutput();
  $BMAModel->setName($self->getName());
  $self->setOutput($BMAModel);
}

1;
