# Tractable Bayesian Model Averaging TAN inducer

package Durin::TBMATAN::TBMATANInducer;

use Durin::Classification::Inducer;

use base "Durin::Classification::Inducer";
use PDL;

use strict;
use warnings;

use Durin::TBMATAN::TBMATAN;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("TBMATAN");
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
  
  # We do nothing but counting and calculating the betas.

  my $input = $self->getInput();
  my $table = $input->{TABLE};
  
  print "Starting counting\n";
  my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  {
    my $input = {};
    $input->{TABLE} = $table;
    $input->{ORDER} = 2;
    $bc->setInput($input);
  }
  $bc->run();
  
  print "Done with counting\n";
  
  print "Calculating betas\n";
  
  my $num_atts = $input->{TABLE}->getSchema()->getNumAttributes()-1;
  my $betas = ones $num_atts,$num_atts;
  $betas = $betas * (1000/ ($num_atts * $num_atts));
  
  my $TBMATAN = Durin::TBMATAN::TBMATAN->new();
  
  $TBMATAN->setSchema($table->getMetadata()->getSchema());
  $TBMATAN->setCountTable($bc->getOutput);
  $TBMATAN->setBetaMatrix($betas);
  $TBMATAN->setName($self->getName());  
  $self->setOutput($TBMATAN);
}

1;
