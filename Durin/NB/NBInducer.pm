package Durin::NB::NBInducer;

use Durin::Classification::Inducer;

@ISA = (Durin::Classification::Inducer);

use strict;

use Durin::ProbClassification::ProbApprox::Counter;
use Durin::NB::NB;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
    $self->setName("NB");
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
  my ($self) = @_;
  
  my $table = $self->getInput()->{TABLE};

  my $PA;
  if (exists $self->getInput()->{PROBAPPROX})
    { 
      $PA = $self->getInput()->{PROBAPPROX};
    }
  else
    {
      $PA = Durin::ProbClassification::ProbApprox::PABIBL->new();
    }
  
  my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  {
    my $input = {};
    $input->{TABLE} = $table;
    $input->{ORDER} = 1;
    $bc->setInput($input);
  }
  $bc->run();
  my $ct = $bc->getOutput();
  $PA->setCountTable($ct);
  
  #$bc->setOutput(undef);
  
  # We create the model
  my $NB = Durin::NB::NB->new();
  $NB->setSchema($table->getMetadata()->getSchema());
  $NB->setProbApprox($PA);
  $NB->setName($self->getName());
  $self->setOutput($NB);
}

1;
