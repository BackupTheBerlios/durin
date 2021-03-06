# Random TAN Inducer

package Durin::TAN::RandomTANInducer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::ProbClassification::ProbApprox::Counter;
use Durin::TAN::RandomGraphConstructor;
use Durin::ProbClassification::ProbApprox::PAFG;
#use Durin::TAN::Kruskal;
use Durin::Algorithms::Kruskal;
use Durin::TAN::TAN;
use Durin::DataStructures::Graph;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
  my ($self) = @_;
  
  my $input = $self->getInput();
  my $table = $input->{TABLE};
  #my $PAGC = $input->{GC}->{PROBAPPROX};
  #my $PATAN = $input->{TAN}->{PROBAPPROX};
  my $PATAN = Durin::ProbClassification::ProbApprox::PAFG->new();

  my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  {
    my $input = {};
    $input->{TABLE} = $table;
    $input->{ORDER} = 2;
    $bc->setInput($input);
  }
  #$bc->setInput($table);
  $bc->run();
  #  my @tablesRef = @{$bc->getOutput()};
  
  #$PAGC->setCountTable($bc->getOutput());
  $PATAN->setCountTable($bc->getOutput());
  
  my $gcons = Durin::TAN::RandomGraphConstructor->new();
  {
    my ($Input);
    #$Input->{PROBAPPROX} = $PAGC;
    $Input->{SCHEMA} = $table->getMetadata()->getSchema();
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
  
  # print "The undirected spanning tree is:\n";
  #my @edges = @{$UTree->getEdges()};
  #foreach my $p (@edges)
  #  {
  #  print ${@$p}[0],",",${@$p}[1], "\n";
  #}
  
  my $Tree = $UTree->makeDirected();
  
  #my @nodes =  @{$UTree->getNodes()};
  
  #foreach my $n (@nodes)
  #  {
  #	$Tree->addEdge($table->getMetadata()->getSchema()->getClassPos(),$n,1);
  
  # Now we have a directed tree. With these and the count matrix we are done.
  # }
  
  my $TAN = Durin::TAN::TAN->new();
  #print " Durin::TAN::TANInducer there should be a clone here\n";
  $TAN->setSchema($table->getMetadata()->getSchema());
  $TAN->setProbApprox($PATAN);
  $TAN->setTree($Tree);
  $TAN->setName("RandomTAN");
  $self->setOutput($TAN);
}

1;
