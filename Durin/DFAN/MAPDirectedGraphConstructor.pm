# Constructs a graph with an weighted edge from attribute A to attribute B as described in Cerquides paper. We add an additional node R (from Root) and a weigthed edge from every attribute A to R.

package Durin::TAN::MAPDirectedGraphConstructor;

use strict;
use warnings;

use Durin::Components::Process;

@Durin::TAN::MAPDirectedGraphConstructor::ISA = qw/Durin::Components::Process/;

use Class::MethodMaker
  get_set => [ -java => qw/EquivalentSampleSize InternalNQuoteUC InternalNQuoteUVC NQuoteC Schema/];

use Durin::DataStructures::Graph;
use Math::Gsl::Sf;
use PDL;

sub new_delta {
  my ($class,$self) = @_;
  
  #$self->{PRIOR} = $self->createPrior();
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub getLambda {
  return 1;
}

sub run($) {
  my ($self) = @_;
  
  my ($Graph,$arrayofTablesRef,$schema,$num_atts,$class_attno,$class_att,$info2,$PA,$infoFunction);
  
  $schema = $self->getInput()->{SCHEMA};
  $self->setSchema($schema);
  $self->setEquivalentSampleSizeAndInitialize($self->getLambda());
  
  my $data = $self->getInput()->{COUNTING_TABLE};
  
  if (defined $self->getInput()->{PRIOR}) {
    $self->{PRIOR} = $self->getInput()->{PRIOR};
  }
  my $prior = $self->{PRIOR};
  
  $Graph = Durin::DataStructures::Graph->new();
  
  $class_attno = ($schema->getClassPos());
  $class_att = $schema->getAttributeByPos($class_attno);
  $num_atts = $schema->getNumAttributes();
  

  # Calculate the edges from A to B
  my ($j,$k,$info);
  foreach $j (0..$num_atts-1) {
    if ($j!=$class_attno) {
      #foreach $k (0..$j-1) {
      foreach $k (0..$num_atts-1) {
	if ($k!=$class_attno && $k!=$j) {
	  $info = $self->calculateA_BLogProbabilityWeigth($j,$k,$class_att,$schema,$data);
	  print "Adding edge $j -> $k , $info\n";
	  $Graph->addEdge($j,$k,$info);
	}
      }
    }
  }
  
  # Add the edges from R to A
  # The root will have value -1;

  my $R = -1;
  foreach $j (0..$num_atts-1) {
    if ($j!=$class_attno) {
      $info = $self->calculateRoot_ALogProbabilityWeigth($j,$class_att,$schema,$data);
      $Graph->addEdge($R,$j,$info);
      #print "Adding edge $j -> $R, $info\n";

    }
  }
  $self->setOutput($Graph);
}
	

sub calculateA_BLogProbabilityWeigth {
  my ($self,$j,$k,$class_att,$schema,$data) = @_;
  
  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  my ($Pxyz,$Pz,$Pxz,$Pyz,$quotient,$temp,$infoTotal,$infoPartial);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  my $total = 0.0;
  my ($nquote,$n);
  
  foreach $class_val (@class_values) {	
    foreach $j_val (@j_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val); 
      $nquote = $self->getNQuoteUC($j);
      $n = $data->getCountXClass($class_val,$j,$j_val);
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n);
      foreach $k_val (@k_values) {
	#$nquote = $prior->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	$nquote = $self->getNQuoteUVC($j,$k);
	$n = $data->getCountXYClass($class_val,$j,$j_val,$k,$k_val);
	$total += Math::Gsl::Sf::lngamma($nquote + $n);
	$total -= Math::Gsl::Sf::lngamma($nquote);
      }
    }
  }
  #print "Info ($j,$k) = $infoTotal\n";
  return $total;
}

sub calculateRoot_ALogProbabilityWeigth {
  my ($self,$j,$class_att,$schema,$data) = @_;
  
  my ($class_val,@class_values,@j_values,$j_val);
  my ($Pxyz,$Pz,$Pxz,$Pyz,$quotient,$temp,$infoTotal,$infoPartial);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  
  my $total = 0.0;
  my ($nquote,$n);
  
  foreach $class_val (@class_values) {	
    #$nquote = $prior->getCountClass($class_val);
    $nquote = $self->getNQuoteC();
    $n = $data->getCountClass($class_val);
    $total += Math::Gsl::Sf::lngamma($nquote);
    $total -= Math::Gsl::Sf::lngamma($nquote + $n);
    foreach $j_val (@j_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val);
      $nquote = $self->getNQuoteUC($j);
      $n = $data->getCountXClass($class_val,$j,$j_val);
      $total += Math::Gsl::Sf::lngamma($nquote + $n);
      $total -= Math::Gsl::Sf::lngamma($nquote);
    }
  }
  #print "Info ($j,$k) = $infoTotal\n";
  return $total;
}

sub setEquivalentSampleSizeAndInitialize {
  my ($self,$size) = @_;
  
  $self->setEquivalentSampleSize($size);
  $self->initializeSampleSize();
}

sub initializeSampleSize {
  my ($self) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();
  my $nQuoteUC = zeroes $num_atts;
  my $nQuoteUVC = zeroes $num_atts,$num_atts;
  
  my $nquote = $self->getEquivalentSampleSize();
  my $nquotec = $nquote/$class_card;
  $self->setNQuoteC($nquotec);
  
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      my $card_u = $schema->getAttributeByPos($node_u)->getType()->getCardinality();
      my $nQuoteUCVal = $nquotec/$card_u;
      #print "nQuoteUC($node_u) = $nQuoteUCVal\n";
      $nQuoteUC->set($node_u,$nQuoteUCVal);
      for (my $node_v = 0 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    # Calculate nQuoteUVC
	    my $card_v = $schema->getAttributeByPos($node_v)->getType()->getCardinality();
	    my $nQuoteUVCVal = $nQuoteUCVal/$card_v ;
	    #print "nQuoteUVC($node_u,$node_v) = $nQuoteUVCVal\n";
	    $nQuoteUVC->set($node_u,$node_v,$nQuoteUVCVal);
	  }
	}
      }
    }
  }
  $self->setInternalNQuoteUC($nQuoteUC);
  $self->setInternalNQuoteUVC($nQuoteUVC);
}

sub getNQuoteUVC {
  my ($self,$node_u,$node_v) = @_;
  
  return $self->getInternalNQuoteUVC()->at($node_u,$node_v);
}

sub getNQuoteUC {
  my ($self,$node_u) = @_;
  
  return $self->getInternalNQuoteUC()->at($node_u);
}


1;
