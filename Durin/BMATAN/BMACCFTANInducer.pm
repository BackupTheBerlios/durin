#CARE!!!! OBSOLETE

package Durin::BMATAN::BMACCFTANInducer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::BMATAN::FirstMTANGenerator;
use Durin::TAN::TANInducer;
#use Durin::ProbClassification::ProbApprox::PAFrequency;
use Durin::ProbClassification::ProbApprox::PACoherent;
use Durin::BMATAN::BMATANInducer;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{INDUCER} = Durin::BMATAN::BMATANInducer->new();
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
    my $PA1 = Durin::ProbClassification::ProbApprox::PACoherent->new();
    $input->{GC}->{PROBAPPROX} = $PA1;
    my $PA2 = Durin::ProbClassification::ProbApprox::PACoherent->new();
    $input->{TAN}->{PROBAPPROX} = $PA2;
    #$input->{MTANG} = Durin::BMATAN::FirstMTANGenerator->new();
    $input->{MTANG} = Durin::BMATAN::FirstMTANGenerator->new();
    
    $inducer->setInput($input);
  }
  $inducer->run(); 
  my $BMAModel = $inducer->getOutput();
  $BMAModel->setName("BMACCFTAN");
  $self->setOutput($BMAModel);
}


1;
