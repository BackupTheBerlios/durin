package Durin::BN::BN;

use strict;
use warnings;

use base 'Durin::Classification::Model';
use Class::MethodMaker get_set => [-java => qw/ Graph CPTHash/];

#use Durin::Data::MemoryTable;
use Durin::Math::Prob::Multinomial;
use Durin::DataStructures::Graph;

sub new_delta {
  my ($class,$self) = @_;
  
  $self->setGraph(Durin::DataStructures::Graph->new());
  $self->setCPTHash({});
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
  
  die "Durin::BN::BN clone not implemented";
  #   $self->setMetadata($source->getMetadata()->clone());
}

sub addEdge {
  my ($self,$parent,$son) = @_;
  
  $self->getGraph()->addEdge($parent,$son);
}

sub addCPT {
  my ($self,$node,$parentConfiguration,$conditionalProbabilityTable) = @_;
  
  if (!exists $self->getCPTHash()->{$node}) {
    $self->getCPTHash()->{$node} = {};
  }
  my $CPTHash = $self->getCPTHash()->{$node};
  
  foreach my $parentValue (@$parentConfiguration) {
    if (!exists $CPTHash->{$parentValue}) {
      $CPTHash->{$parentValue} = {};
    }
    $CPTHash = $CPTHash->{$parentValue};
  }
  my $multinomial = Durin::Math::Prob::Multinomial->new();
  $multinomial->setDimensions(1);
  $multinomial->setCardinalities([scalar @$conditionalProbabilityTable]);
  my $prob = 0;
  my $probTot = 0;
  my $i;
  for ($i = 0; $i < (scalar (@$conditionalProbabilityTable)-1) ; $i++) {
    $prob = $conditionalProbabilityTable->[$i];
    $probTot += $prob;
    print "Prob: $prob\n";
    $multinomial->setP([$i],$prob);
  }
  $multinomial->setP([$i],1-$probTot);
  $multinomial->prepareForSampling();
  $CPTHash->{1} = $multinomial;
}

sub generateObservation {
  my ($self) = @_;
  
  my $row = [];
  my $numAttributes = $self->getSchema()->getNumAttributes();
  for (my $i = 0; $i < $numAttributes; $i++) {
    $row->[$i] = undef;
  }
  for (my $i = 0; $i < $numAttributes; $i++) {
    $self->generateValue($row,$i);
  }
  return $row;
}

sub generateValue {
  my ($self,$row,$i) = @_;

  my $parents = $self->getGraph()->getParents($i);
  my $CPTHash = $self->getCPTHash()->{$i};
  foreach my $parent (@$parents) {
    if (!defined $row->[$parent]) {
      $self->generateValue($row,$parent);
    }
    $CPTHash = $CPTHash->{$row->[$parent]};
  }
  if (!defined $row->[$i]) {
    my $valIndex= $CPTHash->{1}->sample()->[0];
    print "Val gen: $valIndex\n";
    $row->[$i] = $self->getSchema()->getAttributeByPos($i)->getType()->getValue($valIndex);
  }
}

1;
