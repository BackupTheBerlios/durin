# Structure Stubborn Tractable Bayesian Model Averaging TAN inducer

package Durin::TBMATAN::SSTBMATANInducer;

use Durin::Classification::Inducer;

use base "Durin::Classification::Inducer";
use PDL;

use strict;
use warnings;

use Durin::TBMATAN::ATBMATAN;
use Durin::TBMATAN::BaseTBMATAN;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->setName("SSTBMATAN");
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub getStubbornness {
  return Durin::TBMATAN::BaseTBMATAN::HardMinded;
}

#sub getLambda {
#  return 6*6*6;
#}

sub run
{
  my ($self) = @_;
  
  # We do nothing but counting and calculating the betas.

  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $schema = $table->getMetadata()->getSchema();
  my $lambda = $schema->calculateLambda();
  print "Assuming Lambda = ".$lambda."\n";
  #print "Starting counting\n";
 # my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
#  {
#    my $input = {};
#    $input->{TABLE} = $table;
#    $input->{ORDER} = 2;
#    $bc->setInput($input);
#  }
#  $bc->run();
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
  
  my $num_atts = $schema->getNumAttributes()-1;
  my $betas = ones $num_atts,$num_atts;
  #$betas = $betas * exp(3.4*$bc->getOutput()->getCount);
  
  my $SSTBMATAN = Durin::TBMATAN::ATBMATAN->new();
  
  my $stubbornness = $self->getStubbornness();
  #print "$jar\n";
  $SSTBMATAN->setStructureStubbornness($stubbornness);
  $SSTBMATAN->setSchema($schema);
  $SSTBMATAN->setBetaMatrix($betas);
  $SSTBMATAN->setName($self->getName());
  #$TBMATAN->setEquivalentSampleSizeAndInitialize(
  #$self->CalculateEquivalentSampleSize(
  #$table->getMetadata()->getSchema())/100);
  $SSTBMATAN->setEquivalentSampleSizeAndInitialize($lamdba);
  $SSTBMATAN->setCountTableAndInitialize($self->{COUNTING_TABLE});
  
  $self->setOutput($SSTBMATAN);
}

sub getDetails()
  {
    my ($class) = @_;
    return {"Softening constant" => "adjusted from dataset",
	    "Stubborness" => $class->getStubbornness()};
  }
1;
