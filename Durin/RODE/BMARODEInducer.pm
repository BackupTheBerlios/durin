# BMA Restricted One Dependence Estimator Inducer

package Durin::RODE::RODInducer;

use Durin::Classification::Inducer;

use base "Durin::Classification::Inducer";
use PDL;

use strict;
use warnings;

use Durin::RODE::RODEDecomposable;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("BMARODE");
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub getStubbornness {
  return 1;
}

sub run
{
  my ($self) = @_;
  
  # We do nothing but counting and calculating the betas.

  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $schema = $table->getMetadata()->getSchema();
  my $lambda = $schema->calculateLambda();
  print "Assuming Lambda = ".$lambda."\n";
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
  
  my $num_atts = $schema->getNumAttributes();
  my $alphas = [];
  foreach my $node_u (0..$num_atts-1) {
    push @$alphas, 1;
  }

  my $RODEDecomposable = Durin::RODE::RODEDecomposable->new();
  my $stubbornness = $self->getStubbornness();

  $RODEDecomposable->setStructureStubbornness($stubbornness);
  $RODEDecomposable->setSchema($schema);
  # Set the prior
  $RODEDecomposable->setAlphas($alphas);
  $RODEDecomposable->setEquivalentSampleSizeAndInitialize($lambda);

  $RODEDecomposable->setName($self->getName());
  $RODEDecomposable->learn($self->{COUNTING_TABLE});
  
  $self->setOutput($RODEDecomposable);
}

sub getDetails()
  {
    my ($class) = @_;
    return {"Softening constant" => "adjusted from dataset",
	    "Stubborness" => $class->getStubbornness()};
  }
1;
