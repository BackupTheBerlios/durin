package Durin::TBMATAN::BaseTBMATAN;

use base "Durin::Classification::Model";

use Class::MethodMaker
  get_set => [ -java => qw/CountTable BetaMatrix EquivalentSampleSize InternalNQuoteUC InternalNQuoteUVC WuvMatrix StructureStubbornness/];


use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;
use Math::Gsl::Sf;
use ntl;

use strict;
use warnings;

use constant NoStubbornness => "1";
use constant HardMinded => "2";
use constant Constant => "3";


sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setCountTable(undef);
  # Structure stubbornness can be one of NoStubbornness,HardMinded,Constant
  # No stubbornness means TBMATAN.
  # HardMinded means softening the betas to make them all over 10E-3.
  # Constant means no change in betas.
  $self->setStructureStubbornness(NoStubbornness);
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::TAN::TAN clone not implemented";
}

sub setCountTableAndInitialize  {
  my ($self,$ct) = @_;
  
  $self->setCountTable($ct);

  # And calculate the Wuv

  $self->initializeWuvMatrix();
}

sub initializeWuvMatrix {
  my ($self) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();
  my $WuvMatrix = zeroes $num_atts,$num_atts;
  my $reductionFactor = undef;

  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      for (my $node_v = $node_u+1 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    my $lnWuv = 0;
	    #print $self->getStructureStubbornness()."\n";
	    #print "Constant is ".Constant."\n";
	    if (!($self->getStructureStubbornness() eq Constant)) {
	      $lnWuv =  $self->CalculateConstantLogWuv($node_u,$node_v);
	    }
	    #print "Wuv constant($node_u,$node_v) = $lnWuv\n";
	    $WuvMatrix->set($node_u,$node_v,$lnWuv);
	    $WuvMatrix->set($node_v,$node_u,$lnWuv);
	  }
	}
      }
    }
  }
  if ($self->getStructureStubbornness() eq HardMinded) {
    $self->softenBetas($schema,$WuvMatrix);
  }
  
  #  print "Done with WuvMatrix initialization\n";
  $self->setWuvMatrix($WuvMatrix);
}

sub softenBetas {
  my ($self,$schema,$WuvMatrix) = @_;
  
  # Soften weights to the [StMin,StMax] interval
  my ($min,$max) = @{$self->calculateMinMax($schema,$WuvMatrix)};
  my $StMin = -11.51;
  my $StMax = 0;
  if (($max-$min)<($StMax-$StMin)) {
    # Do never exagerate beliefs. If the difference 
    # is not so marked keep it as it is and just move 
    # it to be around 0 ($a will be 1).
    $StMax = $StMin+($max-$min);
  }
  print "Max-Min = $max, $min\n";
  my $a = ($StMax-$StMin)/($max-$min);
  my $b = $StMin-$a*$min;
  #print "Max: $max, Min: $min, StMax:$StMax, StMin:$StMin, a:$a, b;$b\n";
  my $class_attno = $schema->getClassPos();
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      for (my $node_v = $node_u+1 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    my $lnWuv = $WuvMatrix->at($node_u,$node_v);
	    #print "We enter with $lnWuv\n";
	    $lnWuv = $a*$lnWuv+$b; 
	    #print "And we get out with $lnWuv\n";
	    $WuvMatrix->set($node_u,$node_v,$lnWuv);
	    $WuvMatrix->set($node_v,$node_u,$lnWuv);
	  }
	}
      }
    }
  }
}

sub calculateMinMax {
  my ($self,$schema,$WuvMatrix) = @_;

  my $min = undef;
  my $max = undef;
  my $class_attno = $schema->getClassPos();
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      for (my $node_v = $node_u+1 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    my $lnWuv = $WuvMatrix->at($node_u,$node_v);
	    if ((!defined $min) || ($min > $lnWuv)) {
	      $min = $lnWuv;
	    }
	    if ((!defined $max) || ($max < $lnWuv)) {
	      $max = $lnWuv;
	    }
	  }
	}
      }
    }
  }
  return [$min,$max];
}
  
sub soften {
  my ($self,$lnWuv,$reductionFactor) = @_;
  
  my $precision = 2000;
  
  $lnWuv = $lnWuv-$reductionFactor;
  print "After reduction: $lnWuv\n";
  #print "Max:$max Min:$min MaxDiff:$maxDiff Precision (in bits): $precision\n";
  ntl::RR_SetPrecision($precision);
  my $x = ntl::new_RR();
  my $tmp = ntl::new_RR();
  ntl::RR_SetDoubleValue($x,$lnWuv);
  ntl::RR_exp($tmp,$x);
  ntl::RR_addDouble($tmp,1.01);
  ntl::RR_log($x,$tmp);
  my $Wuv = ntl::RR_GetDoubleValue($x);
  ntl::delete_RR($tmp);
  ntl::delete_RR($x);
  return log($Wuv);
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

sub  CalculateLogWuv {
  my ($self,$row_to_classify,$class_val,$node_u,$node_v) = @_;
  
  my $lnWuvConstant = $self->getWuvMatrix()->at($node_u,$node_v);
  my $ct = $self->getCountTable();

  my $u_val = $row_to_classify->[$node_u];
  my $v_val = $row_to_classify->[$node_v];
  my $count = $ct->getCountXYClass($class_val,$node_u,$u_val,$node_v,$v_val);
  my $nquote = $self->getNQuoteUVC($node_u,$node_v);
  my $factor1 = log($count+$nquote);
  
  $nquote = $self->getNQuoteUC($node_u);
  $count = $ct->getCountXClass($class_val,$node_u,$u_val);
  my $factor2 = log($count+$nquote);
  $nquote = $self->getNQuoteUC($node_v);
  $count = $ct->getCountXClass($class_val,$node_v,$v_val);
  my $factor3 = log($count+$nquote);
  
  return $lnWuvConstant+$factor1-$factor2-$factor3;
}

sub  CalculateConstantLogWuv{
  my ($self,$node_u,$node_v) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};

  #print "Nodes: $node_u, $node_v\n";
  my $att_u = $schema->getAttributeByPos($node_u);
  my @u_values = @{$att_u->getType()->getValues()};
  my $att_v = $schema->getAttributeByPos($node_v);
  my @v_values = @{$att_v->getType()->getValues()};

  my $ct = $self->getCountTable();
  
  my $lnWuv = 0;
  
  foreach my $class_val_iter (@class_values) {
    foreach my $u_val (@u_values) {
      foreach my $v_val (@v_values) {
	my $count = $ct->getCountXYClass($class_val_iter,$node_u,$u_val,$node_v,$v_val);
	my $nquote = $self->getNQuoteUVC($node_u,$node_v);
	my $lnGamma = Math::Gsl::Sf::lngamma($count+$nquote);
	#print "LnGamma($count+$nquote+$beta)=$lnGamma\n";
	$lnWuv = $lnWuv + $lnGamma;
	
	# And now the N'uvc
	
	$lnGamma = Math::Gsl::Sf::lngamma($nquote);
	$lnWuv = $lnWuv - $lnGamma;
      }
    }
    my $nquote = $self->getNQuoteUC($node_u);
    foreach my $u_val (@u_values) {
      my $count = $ct->getCountXClass($class_val_iter,$node_u,$u_val);
      my $lnGamma = Math::Gsl::Sf::lngamma($count+$nquote);
      
      #print "LnGamma($count+$nquote+$beta)=$lnGamma\n";
      $lnWuv = $lnWuv - $lnGamma;
      
      # And now the N'uc
      
      $lnGamma =Math::Gsl::Sf::lngamma($nquote);
      $lnWuv = $lnWuv + $lnGamma;
    }
    $nquote = $self->getNQuoteUC($node_v);
    foreach my $v_val (@v_values) {
      my $count = $ct->getCountXClass($class_val_iter,$node_v,$v_val);
      my $lnGamma =Math::Gsl::Sf::lngamma($count+$nquote);
      #print "LnGamma($count+$nquote+$beta)=$lnGamma\n";
      $lnWuv = $lnWuv - $lnGamma;
      
      # And now the N'uc
      
      $lnGamma =Math::Gsl::Sf::lngamma($nquote);
      $lnWuv = $lnWuv + $lnGamma;
    }
  }
  return $lnWuv;
}


sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

1;
