package Durin::BMATAN::BMATANInducer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

#use Durin::BMATAN::MultipleTANGenerator;
use Durin::ProbClassification::BMAInducer;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
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
  my $MTG = $self->getInput()->{MTANG};
  #print $table->getMetadata(),"\n";
  #my $MTG = Durin::BMATAN::MultipleTANGenerator->new();
  {
    my $input = {};
    $input->{TABLE} = $table;
    $input->{GC} = $self->getInput()->{GC};
    $input->{TAN} = $self->getInput()->{TAN};
    $input->{K} = 10;
    $MTG->setInput($input);
  }
  $MTG->run();
  my $TANList = $MTG->getOutput();
  my $BMAI = Durin::ProbClassification::BMAInducer->new();
  {
    my $input = {};
    $input->{TABLE} = $table;
    $input->{MODELLIST} = $TANList;
    $BMAI->setInput($input);
  }
  $BMAI->run();
  $self->setOutput($BMAI->getOutput());
}

1;
