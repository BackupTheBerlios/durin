package Durin::BMATAN::MultipleTANGenerator;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::ProbClassification::ProbApprox::Counter;
use Durin::TAN::GraphConstructor;
#use Durin::BMATAN::KKruskal;
use Durin::Algorithms::Gabow;
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

sub run
  {
    my ($self) = @_;
  
    my $input = $self->getInput();
    my $table = $input->{TABLE};
    my $PAGC = $input->{GC}->{PROBAPPROX};
    my $PATAN = $input->{TAN}->{PROBAPPROX};
    my $k = $input->{K};
    my $kkruskal;
    if (exists $input->{MTREEGEN})
      {
	$kkruskal = $input->{MTREEGEN};
      }
    else
      {
	$kkruskal = Durin::Algorithms::Gabow->new();
      }
    
    my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
    {
      my $input = {};
      $input->{TABLE} = $table;
      $input->{ORDER} = 2;
      $bc->setInput($input);
    }
    #$bc->setInput($table);
    $bc->run();

    $PAGC->setCountTable($bc->getOutput());
    $PATAN->setCountTable($bc->getOutput());
    
    my $gcons = Durin::TAN::GraphConstructor->new();
    {
      my ($Input);
      $Input->{PROBAPPROX} = $PAGC;
      $Input->{SCHEMA} = $table->getMetadata()->getSchema();
      $gcons->setInput($Input);
    }
    $gcons->run();
    
    my $graph = $gcons->getOutput();
    
    #my $kkruskal = Durin::Algorithms::Gabow->new();
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
    
    my @TANList = ();
    foreach my $Tree (@$Trees)
      {
	#my $Tree = $UTree->makeDirected();
	
	my $TAN = Durin::TAN::TAN->new();
	$TAN->setSchema($table->getMetadata()->getSchema());
	$TAN->setProbApprox($PATAN);
	$TAN->setTree($Tree);
	push @TANList,($TAN); 
	
	#$Input->{MODEL} = $TAN;
	
	#$MA->setInput($Input);
	#$MA->run();
	#my $acc_data = $MA->getOutput();
	#my $weight = ($acc_data->[0])/($acc_data->[0] + $acc_data->[1]);
	#print "GOOD: ",$acc_data->[0]," BAD: ",$acc_data->[1]," weight: $weight\n";
	
      } 
    $self->setOutput(\@TANList);
  }

1;
