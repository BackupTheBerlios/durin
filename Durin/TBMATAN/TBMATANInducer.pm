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

#sub getLambda {
#  return 10;
#}

sub run
{
  my ($self) = @_;
  
  # We do nothing but counting and calculating the betas.

  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $schema = $table->getMetadata()->getSchema();
  my $lambda = $schema->calculateLambda();
  
  #print "Starting counting\n";
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
  # my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  #  {
#    my $input = {};
#    $input->{TABLE} = $table;
#    $input->{ORDER} = 2;
  #    $bc->setInput($input);
  #  }
  #  $bc->run();
  
  #print "Done with counting\n";
  
  #print "Calculating betas\n";
  
  my $num_atts = $schema->getNumAttributes()-1;
  my $betas = ones $num_atts,$num_atts;
  #$betas = $betas * exp(3.4*$bc->getOutput()->getCount);
  
  my $TBMATAN = Durin::TBMATAN::TBMATAN->new();
  
  $TBMATAN->setSchema($schema);
  $TBMATAN->setBetaMatrix($betas);
  $TBMATAN->setName($self->getName());
  #$TBMATAN->setEquivalentSampleSizeAndInitialize(
  #$self->CalculateEquivalentSampleSize(
  #$table->getMetadata()->getSchema())/100);
  $TBMATAN->setEquivalentSampleSizeAndInitialize($lambda);
  $TBMATAN->setCountTableAndInitialize($self->{COUNTING_TABLE});
  $self->setOutput($TBMATAN);
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
    
    return {"TBMATAN softening constant" => "adjusted by dataset"};
  }
1;
