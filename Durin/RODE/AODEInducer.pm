# One Dependence Estimator Inducer

package Durin::RODE::AODEInducer;

use Durin::Classification::Inducer;

use base "Durin::Classification::Inducer";
use PDL;

use strict;
use warnings;

use Durin::RODE::AODEModel;

sub new_delta
{ 
  my ($class,$self) = @_;
  
  $self->setName("AODE");
  #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
  my ($class,$self,$source) = @_;
  
  #   $self->setMetadata($source->getMetadata()->clone());
}

sub getMinimumCount {
  return 30;
}

sub run
{
  my ($self) = @_;
  
  # We do nothing but counting and calculating the betas.
  
  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $schema = $table->getMetadata()->getSchema();
  #my $lambda = $schema->calculateLambda();
  #print "Assuming Lambda = ".$lambda."\n";
  if (!defined $input->{COUNTING_TABLE}) {
    my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
    {
      my $input = {};
      $input->{TABLE} = $table;
      $input->{ORDER} = 2;
      $bc->setInput($input);
    }
    $bc->run();
    $self->{COUNTING_TABLE} = $bc->getOutput(); 
  } else {
    print "Sharing counting table\n";
    $self->{COUNTING_TABLE} = $input->{COUNTING_TABLE};
  }
  #print "Done with counting\n";
  
  #print "Calculating betas\n";
  
  
  my $AODEModel = Durin::RODE::AODEModel->new();
  $AODEModel->setSchema($schema);
  $AODEModel->setName($self->getName());
  $AODEModel->setMinimumCount($self->getMinimumCount());
  $AODEModel->learn($self->{COUNTING_TABLE});
  
  $self->setOutput($AODEModel);
}

sub getDetails()
  {
    my ($class) = @_;
    return {"Minimum count" => $class->getMinimumCount()};
  }
1;
