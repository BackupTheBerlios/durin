# MAP DFAN Inducer based on directed trees instead of undirected ones.

package Durin::DFAN::MAPDFANInducer;

use warnings;
use strict;

use Durin::Components::Process;

#@Durin::TAN::MAPDirectedTANInducer::ISA = Durin::Classification::Inducer);
use base 'Durin::Classification::Inducer';

use Class::MethodMaker
  get_set => [ -java => qw/Schema/];

use Durin::ProbClassification::ProbApprox::Counter;
use Durin::DFAN::MAPDirectedGraphConstructor;
use Durin::Algorithms::Edmonds;
use Durin::DFAN::DFAN;
use Durin::DataStructures::Graph;

sub new_delta  {
  my ($class,$self) = @_;
  $self->setName("DFAN+L");
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
  
  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $PATAN;
  if (!defined  $input->{DFAN}->{PROBAPPROX}) {
    $PATAN = Durin::ProbClassification::ProbApprox::PALaplace->new();
  } else {
    $PATAN = $input->{DFAN}->{PROBAPPROX};
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
    $self->{COUNTING_TABLE} = $input->{COUNTING_TABLE};
  }
  
  $PATAN->setCountTable($self->{COUNTING_TABLE});
  
  # We create the matrix with the different gammas and betas.
  
  my $gcons = Durin::TAN::MAPDirectedGraphConstructor->new();
  {
    my ($Input);
    #$Input->{INFOFUNCTION} = \&calculateInfDifference;
    $Input->{COUNTING_TABLE} = $self->{COUNTING_TABLE};
    $Input->{SCHEMA} = $table->getMetadata()->getSchema();
    $gcons->setInput($Input);
  }
  $gcons->run();
  my $graph = $gcons->getOutput();
  #print "Generated the adjacency matrix\n";
  
  # We calculate the DMST rooted at the 
  # artificially created attribute -1.
  
  my $edmonds = Durin::Algorithms::Edmonds->new();
  {
    my $input = {};
    $input->{GRAPH} = $graph;
    $input->{ROOT} = -1;
    $edmonds->setInput($input);
  }
  $edmonds->run();
  my $edmondsTree = $edmonds->getOutput()->{TREE};

  # The tree returned has an additional node. 
  # We shall remove it 
  
  my $DFAN = $self->makeDFAN($table->getMetadata()->getSchema(),$PATAN,$edmondsTree);

  #print " Durin::TAN::TANInducer there should be a clone here\n";
  
  $self->setOutput($DFAN);
}

sub makeDFAN {
  my ($self,$schema,$PATAN,$edmondsTree) = @_;

  my $forest = Durin::DataStructures::Graph->new();
  my $root = $edmondsTree->getRoot();
  foreach my $rootNode (@{$edmondsTree->getSons($root)}) {
    $forest->addNode($rootNode);
    $self->recursivelyAddSons($edmondsTree,$rootNode,$forest);
  }
  my $DFAN = Durin::DFAN::DFAN->new();
  $DFAN->setSchema($schema);
  $DFAN->setProbApprox($PATAN);
  $DFAN->setForest($forest);
  $DFAN->setName($self->getName());
  return $DFAN;
}

sub recursivelyAddSons {
  my ($self,$edmondsTree,$node,$forest) = @_;
  
  foreach my $son (@{$edmondsTree->getSons($node)}) {
    $forest->addEdge($node,$son);
    $self->recursivelyAddSons($edmondsTree,$son,$forest);
  }
}

1;
