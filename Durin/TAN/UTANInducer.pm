# Generic TAN Inducer

package Durin::TAN::UTANInducer;

use strict;
use warnings;

use base 'Durin::Classification::Inducer';

use Durin::ProbClassification::ProbApprox::Counter;
use Durin::TAN::GraphConstructor;
use Durin::Algorithms::Kruskal;
use Durin::TAN::UTAN;
use Durin::DataStructures::Graph;
use Durin::TAN::DecomposableDistribution;

sub new_delta {
  my ($class,$self) = @_; 
  $self->setName("MAPTAN");
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub getCountingTable {
  my ($self) = @_;
  
  return $self->{COUNTING_TABLE};
}

sub calculateLambda {
  my ($self,$schema) = @_;
  
  my $lambda = 2*2*2;
  
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $num_atts = $schema->getNumAttributes();
  
  my $num_classes = scalar  @{$class_att->getType()->getValues()};
  my ($j,$k,$info);
  
  foreach $j (0..$num_atts-1) {
    if ($j!=$class_attno) {
      my $num_j_values = scalar @{$schema->getAttributeByPos($j)->getType()->getValues()};
      foreach $k (0..$j-1) {
	if ($k!=$class_attno) {
	  my $num_k_values = scalar @{$schema->getAttributeByPos($k)->getType()->getValues()};
	  my $product = $num_k_values*$num_j_values*$num_classes;
	  $lambda = $product if $product > $lambda;
	  #$info = &$infoFunc($j,$k);
	  #$Graph->addEdge($j,$k,$info);
	}
      }
    }
  }
  return $lambda;
}


sub run($) {
  my ($self) = @_;
  
  my $input = $self->getInput();
  
  #if (!defined $input->{LAMBDA}) {
 
  my $table = $input->{TABLE};
  my $schema = $table->getMetadata()->getSchema();
  my $lambda = $self->calculateLambda($schema);
  #$input->{LAMBDA};$input->{LAMBDA} = 10;
  print "Assuming Lambda = ".$lambda."\n";
  #}
  
 
  if (defined $input->{GC}->{MUTUAL_INFO_MEASURE}) {
    $self->{GC}->{MUTUAL_INFO_MEASURE} = $input->{GC}->{MUTUAL_INFO_MEASURE};
  } else {
    $self->{GC}->{MUTUAL_INFO_MEASURE} = Durin::TAN::GraphConstructor::Decomposable;
  }
  
  # If we do not receive the counting table, we calculate it
  
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
 
  # Calculate the parameters of the resulting decomposable distribution
  
  my $distrib = Durin::TAN::DecomposableDistribution->createPrior($schema,$lambda);
  $distrib->setCountingTable($self->getCountingTable());
  
  my $gcons = Durin::TAN::GraphConstructor->new();
  {
    my ($Input);
    #$Input->{PROBAPPROX} = $PAGC;
    $Input->{SCHEMA} = $schema;
    $Input->{COUNTING_TABLE} = $self->{COUNTING_TABLE};
    $Input->{DECOMPOSABLE_DISTRIBUTION} = $distrib;
    if (defined $self->{GC}->{MUTUAL_INFO_MEASURE}) {
      $Input->{MUTUAL_INFO_MEASURE} = $self->{GC}->{MUTUAL_INFO_MEASURE};
    }
    $gcons->setInput($Input);
  }
  $gcons->run();
  my $graph = $gcons->getOutput();
  
  my $kruskal = Durin::Algorithms::Kruskal->new();
  {
    my $input = {};
    $input->{GRAPH} = $graph;
    $kruskal->setInput($input);
  }
  $kruskal->run();
  my $UTree = $kruskal->getOutput()->{TREE};
  
  print "The undirected spanning tree is:\n";
  my @edges = @{$UTree->getEdges()};
  foreach my $p (@edges)
    {
      print ${@$p}[0],",",${@$p}[1], "\n";
    }
  my $UTAN = Durin::TAN::UTAN->new();
  #print " Durin::TAN::TANInducer there should be a clone here\n";
  $UTAN->setSchema($schema);
  $UTAN->setDecomposableDistribution($distrib);
  $UTAN->setTree($UTree);
  $UTAN->setName($self->getName());
  $self->setOutput($UTAN); 
  print "Finished learning ".$self->getName()."\n";
}

1;
