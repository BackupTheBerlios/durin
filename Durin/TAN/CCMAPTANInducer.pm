# Cardinality conscious TAN inducer

package Durin::TAN::CCMAPTANInducer;

use strict;
use warnings;

use base 'Durin::TAN::UTANInducer';

use Durin::ProbClassification::ProbApprox::Counter;
use Durin::TAN::GraphConstructor;
use Durin::Algorithms::Kruskal;
use Durin::TAN::UTAN;
use Durin::TAN::DecomposableDistribution;

sub new_delta {
  my ($class,$self) = @_; 
  $self->{INDUCER} = Durin::TAN::UTANInducer->new();
  $self->setName("CCMAPTAN");
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub getCountingTable {
  my ($self) = @_;
  
  return $self->{COUNTING_TABLE};
}

sub run($) {
  my ($self) = @_;
  
  my $inducer = $self->{INDUCER};
  {
    my $input = $self->{INPUT};
    if (!defined $input->{LAMBDA}) {
      $input->{LAMBDA} = 10;
      print "CCMAPTAN: assuming Lambda = ".$input->{LAMBDA}."\n";
    }
    if (!defined $input->{GC}->{MUTUAL_INFO_MEASURE}) {
      $input->{GC}->{MUTUAL_INFO_MEASURE} = Durin::TAN::GraphConstructor::DecomposableCardinalityConscious;
    }
    $inducer->setInput($input);
  }
  $inducer->run();
  my $model = $inducer->getOutput();
  $model->setName($self->getName());
  $self->setOutput($model);
   print "Finished learning ".$self->getName()."\n";
}

1;
