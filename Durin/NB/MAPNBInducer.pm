package Durin::NB::MAPNBInducer;

use Durin::Classification::Inducer;

@ISA = (Durin::Classification::Inducer);

use strict;
use Durin::NB::NBInducer;
use Durin::ProbClassification::ProbApprox::PAMAPNB;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{INDUCER} = Durin::NB::NBInducer->new();
    $self->setName("MLNB");
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
  my ($self) = @_;
  
  my $inducer = $self->{INDUCER};
  {
    my $input = $self->{INPUT};
    $input->{TABLE} = $self->getInput()->{TABLE};
    #print $input->{TABLE}->getMetadata();
    $input->{PROBAPPROX} = Durin::ProbClassification::ProbApprox::PAMAPNB->new();
    $inducer->setInput($input);
  }
  $inducer->run();
  my $model = $inducer->getOutput();
  $model->setName($self->getName());
  $self->setOutput($model);
}

1;
