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

sub getLambda {
  return 6*6*6;
}

sub run
{
  my ($self) = @_;
  
  # We do nothing but counting and calculating the betas.

  my $input = $self->getInput();
  my $table = $input->{TABLE};
  
  #print "Starting counting\n";
  my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  {
    my $input = {};
    $input->{TABLE} = $table;
    $input->{ORDER} = 2;
    $bc->setInput($input);
  }
  $bc->run();
  
  #print "Done with counting\n";
  
  #print "Calculating betas\n";
  
  my $num_atts = $input->{TABLE}->getSchema()->getNumAttributes()-1;
  my $betas = ones $num_atts,$num_atts;
  #$betas = $betas * exp(3.4*$bc->getOutput()->getCount);
  
  my $SSTBMATAN = Durin::TBMATAN::ATBMATAN->new();
  
  my $stubbornness = $self->getStubbornness();
  #print "$jar\n";
  $SSTBMATAN->setStructureStubbornness($stubbornness);
  $SSTBMATAN->setSchema($table->getMetadata()->getSchema());
  $SSTBMATAN->setBetaMatrix($betas);
  $SSTBMATAN->setName($self->getName());
  #$TBMATAN->setEquivalentSampleSizeAndInitialize(
  #$self->CalculateEquivalentSampleSize(
  #$table->getMetadata()->getSchema())/100);
  $SSTBMATAN->setEquivalentSampleSizeAndInitialize($self->getLambda());
  $SSTBMATAN->setCountTableAndInitialize($bc->getOutput);
  
  $self->setOutput($SSTBMATAN);
}

# Inspired in the indifferent naive bayes results
sub CalculateEquivalentSampleSize {
  my ($self,$schema) = @_;
  
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();

  my $sum = 1;
  my $i = 0;
  while ($i < $num_atts) {
    if ($i != $class_attno)
      {
	$sum += $schema->getAttributeByPos($i)->getType->getCardinality;
      }
    $i++;
  }
  $sum = $sum - ($num_atts - 1);
  return $sum * $class_card;
}

sub getDetails()
  {
    my ($class) = @_;
    return {"Softening constant" => $class->getLambda(),
	    "Stubborness" => $class->getStubbornness()};
  }
1;
