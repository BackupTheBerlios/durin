# One Dependence Estimator Inducer

package Durin::RODE::ODEInducer3;

use Durin::Classification::Inducer;

use base "Durin::Classification::Inducer";
use PDL;

use strict;
use warnings;

use Durin::RODE::RODEDecomposable3;

sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setName("SSBMARODE3");
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
  }

sub getStubbornness {
  return Durin::RODE::RODEDecomposable3::ParameterizedStubbornness;
}

sub getParameterizedStubbornnessFactor {
    return 0.99;
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
  
  my $num_atts = $schema->getNumAttributes();
  my $alphas = [];
  my $class_attno = $schema->getClassPos();
  foreach my $node_u (0..$num_atts-1) {
      if ($node_u != $class_attno) {
	  push @$alphas, 1;
      } else {
	  push @$alphas, $num_atts-1;
      }
  }

  my $RODEDecomposable = Durin::RODE::RODEDecomposable3->new();
  my $stubbornness = $self->getStubbornness();
  my $stubbornnessFactor = $self->getParameterizedStubbornnessFactor();
  
  $RODEDecomposable->setStructureStubbornness($stubbornness);
  $RODEDecomposable->setParameterizedStubbornnessFactor($stubbornnessFactor);
  
  #$RODEDecomposable->setStructureStubbornness($stubbornness);
  
  $RODEDecomposable->setSchema($schema);
  # Set the prior
  $RODEDecomposable->setAlphas($alphas);
  #$RODEDecomposable->setEquivalentSampleSizeAndInitialize($lambda);

  $RODEDecomposable->setName($self->getName());
  $RODEDecomposable->learn($self->{COUNTING_TABLE});
  
  $self->setOutput($RODEDecomposable);
}

sub getDetails()
  {
    my ($class) = @_;
    return {"Softening constant" => "fixed to 1",
	    "Stubborness" => $class->getStubbornness()};
  }
1;
