package Durin::BMATAN::BMAUTANInducer;

use strict;
use warnings;

use Durin::Components::Process;

use base 'Durin::Classification::Inducer';

#use Durin::BMATAN::MultipleUTANGenerator;
#use Durin::ProbClassification::BMAInducer;
use Durin::ProbClassification::ProbApprox::Counter;
use Durin::TAN::GraphConstructor;
use Durin::Algorithms::Kruskal;
use Durin::TAN::UTAN;
use Durin::DataStructures::Graph;
use Durin::TAN::DecomposableDistribution;
use Durin::ProbClassification::BMA;

sub new_delta {
  my ($class,$self) = @_;
  $self->setName("MAPTAN+BMA");
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub getNumTrees {
  return 10;
}

sub run($) {
  my ($self) = @_;
  
  my $input = $self->getInput();
  
  $input->{LAMBDA} = 10;
  $input->{GC}->{MUTUAL_INFO_MEASURE} = Durin::TAN::GraphConstructor::Decomposable;
  $input->{K} = $self->getNumTrees();
  
  my $table = $input->{TABLE};
  my $k = $input->{K};
  my $lambda = $input->{LAMBDA};
  my $schema = $table->getMetadata()->getSchema();
  
  my $kkruskal;

  if (defined $input->{GC}->{MUTUAL_INFO_MEASURE}) {
    $self->{GC}->{MUTUAL_INFO_MEASURE} = $input->{GC}->{MUTUAL_INFO_MEASURE};
  }
  
  if (exists $input->{MTREEGEN}) {
    $kkruskal = $input->{MTREEGEN};
  } else {
    $kkruskal = Durin::Algorithms::Gabow->new();
  }
  
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
  
  my $gcons = Durin::TAN::GraphConstructor->new();
  {
    my ($Input);
    #$Input->{PROBAPPROX} = $PAGC;
    $Input->{SCHEMA} = $schema;
    $Input->{COUNTING_TABLE} = $self->{COUNTING_TABLE};
    if (defined $self->{GC}->{MUTUAL_INFO_MEASURE}) {
      $Input->{MUTUAL_INFO_MEASURE} = $self->{GC}->{MUTUAL_INFO_MEASURE};
    }
    $gcons->setInput($Input);
  }
  $gcons->run();
  my $graph = $gcons->getOutput();
  
  {
    my $input = {};
    $input->{GRAPH} = $graph;
    $input->{K} = $k;
    $kkruskal->setInput($input);
  }
  $kkruskal->run();
  my $Trees = $kkruskal->getOutput()->{TREELIST};
  
  foreach my $Tree (@$Trees)
    {
      my $weight = $Tree->getWeight();
      print "Spanning tree with weight $weight and edges:\n";
      my @edges = @{$Tree->getEdges()};
      foreach my $p (@edges)
        {
          print "[$p->[0],$p->[1],$p->[2]]\n";
      }
    }
  
  # Calculate the parameters of the resulting decomposable distribution
  
  my $distrib = Durin::TAN::DecomposableDistribution->createPrior($schema,$lambda);
  $distrib->setCountingTable($self->{COUNTING_TABLE});
  
  # Find the minimum weight in the set
  my $maxWeight = -10000000000000000000000;
  foreach my $UTree (@$Trees) {
      my $thisWeight = $UTree->getWeight();
      if ($maxWeight < $thisWeight) {
	  $maxWeight = $thisWeight;
      }
      print "This = $thisWeight, Max = $maxWeight\n";
  }
  my $BMA = Durin::ProbClassification::BMA->new();
  foreach my $UTree (@$Trees) {
    my $UTAN = Durin::TAN::UTAN->new();
    $UTAN->setSchema($schema);
    $UTAN->setDecomposableDistribution($distrib);
    $UTAN->setTree($UTree);
    $UTAN->setName($self->getName());
    $BMA->addWeightedModel($UTAN,exp($UTree->getWeight()-$maxWeight));
}
  $BMA->normalizeWeights();
  $BMA->setSchema($table->getMetadata()->getSchema());
  $BMA->setName($self->getName());
  $self->setOutput($BMA); 
}
	
sub getDetails {
  my ($class) = @_;
  
  return {"Number of trees averaged" => $class->getNumTrees()};
}

1;
