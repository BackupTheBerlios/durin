# Constructs the graph with the weigths as described Friedman's paper.

package Durin::TAN::GraphConstructor;

use Durin::Components::Process;

use strict;
use warnings;

use base 'Durin::Components::Process';

use Class::MethodMaker
  get_set => [ -java => qw/EquivalentSampleSize InternalNQuoteUC InternalNQuoteUVC NQuoteC Schema/];

use strict;

use Durin::DataStructures::UGraph;
use Math::Gsl::Sf;
use PDL;

use constant MaximumLikelihood=>0;
use constant Decomposable=>1;

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

sub getLambda {
  return 100;
}


sub run($)
{
  my ($self) = @_;
  
  my ($Graph,$arrayofTablesRef,$schema,$num_atts,$class_attno,$class_att,$info2,$PA);
  
  $schema = $self->getInput()->{SCHEMA};
  $self->setSchema($schema);
  $self->setEquivalentSampleSizeAndInitialize($self->getLambda());
  
  #$arrayofTablesRef = $self->getInput()->{ARRAYOFTABLES};
  $PA = $self->getInput()->{PROBAPPROX};
  my $ct = $self->getInput()->{COUNTING_TABLE};
  my $infoMeasure = MaximumLikelihood;
  if (defined $self->getInput()->{MUTUAL_INFO_MEASURE}) {
    $infoMeasure = $self->getInput()->{MUTUAL_INFO_MEASURE};
  }
  $Graph = Durin::DataStructures::UGraph->new();


  $class_attno = ($schema->getClassPos());
  $class_att = $schema->getAttributeByPos($class_attno);
  $num_atts = $schema->getNumAttributes();
  
  my ($j,$k,$info);
  
  foreach $j (0..$num_atts-1)
  {
    if ($j!=$class_attno)
      {
	  foreach $k (0..$j-1)
	    {
	      if ($k!=$class_attno)
		{
		  if ($infoMeasure == MaximumLikelihood) {
		    #print "MaxL\n";
		    $info = $self->calculateInf($j,$k,$class_att,$schema,$PA);
		  } elsif ($infoMeasure == Decomposable) {
		    $info = $self->calculateDecomposableInf($j,$k,$class_att,$schema,$ct);
		  }
		  # $info2 = $self->calculateSmoothedInf($j,$k,$class_att,$schema,$arrayofTablesRef);
		  # print "Info($j,$k): without smoothing p's: $info with smoothing:$info2\n";
		  $Graph->addEdge($j,$k,$info);
	      }
	  }
      }
  }
  $self->setOutput($Graph);
}

sub calculateInf
{
  my ($self,$j,$k,$class_att,$schema,$PA) = @_;

  #my (@arrayofTables,$count,%countClass,%countXClass,%countXYClass);
  
  #@arrayofTables = @$arrayofTablesRef;
  #$count = ${$arrayofTables[0]};
  #%countClass = %{$arrayofTables[1]};
  #%countXClass = %{$arrayofTables[2]};
  #%countXYClass = %{$arrayofTables[3]};

  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  my ($Pxyz,$Pz,$Pxz,$Pyz,$quotient,$temp,$infoTotal,$infoPartial);

  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  $infoTotal = 0.0;

  foreach $class_val (@class_values)
  {	
      foreach $j_val (@j_values)
	{
	  foreach $k_val (@k_values)
	    {
	      $Pxyz = $PA->getPXYClass($class_val,$j,$j_val,$k,$k_val);
	      #print "Pxyz = $Pxyz\n";
	      if ($Pxyz != 0)
		{
		  $infoPartial = $Pxyz * log($PA->getSinergy($class_val,$j,$j_val,$k,$k_val));
		}
	      else
		{
		  $infoPartial = 0;
		}
	      $infoTotal += $infoPartial;
	    }
	}
    }
#print "Info ($j,$k) = $infoTotal\n";
  return $infoTotal;
}

sub calculateDecomposableInf {
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
    foreach $k_val (@k_values) {
      #$nquote = $prior->getCountXClass($class_val,$j,$j_val); 
      $nquote = $self->getNQuoteUC($k);
      $n = $data->getCountXClass($class_val,$k,$k_val);
      $total += Math::Gsl::Sf::lngamma($nquote);
      $total -= Math::Gsl::Sf::lngamma($nquote + $n);
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
