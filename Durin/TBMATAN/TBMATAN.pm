package Durin::TBMATAN::TBMATAN;

use Durin::Classification::Model;

use base "Durin::Classification::Model";

use Class::MethodMaker
  get_set => [ -java => qw/CountTable BetaMatrix EquivalentSampleSize InternalNQuoteUC InternalNQuoteUVC ReductionFactor WuvMatrix MarinaMeilaFormula/];


use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;
use Math::Gsl::Sf;
use ntl;

use strict;
use warnings;

sub new_delta
{
  my ($class,$self) = @_;
  
  $self->setCountTable(undef);
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::TAN::TAN clone not implemented";
}

sub setCountTableAndInitialize  {
  my ($self,$ct) = @_;
  
  $self->setCountTable($ct);

  # We initialize the reduction factor

  my ($row_to_classify,$class_val) = @{$self->CreateRowAndClass()};
  #print join(",",@$row_to_classify)."\n";
  # Take care, there is a minus in the next expression
  my $att1 = 0;
  my $att2 = 1;
  if ($self->getSchema->getClassPos == 0) {
    $att1 = 2;
  } elsif ($self->getSchema->getClassPos == 1) {
    $att2 = 2;
  }
    
  $self->setReductionFactor(-$self->CalculateLnWuv($row_to_classify,$class_val,$att1,$att2));
  #print "Reduction factor:".$self->getReductionFactor()."\n";

  # And calculate the Wuv

  $self->initializeWuvMatrix();

  # Initialize the arithmetic precision

  $self->initializeArithmeticPrecision();
}

sub CreateRowAndClass {
  my ($self) = @_;

  my $schema = $self->getSchema();
  
  my $row = [];
  for (my $i = 0; $i < $schema->getNumAttributes() ; $i++) {
    my $attVal = $schema->getAttributeByPos($i)->getType()->getValues()->[0];
    push @$row,$attVal;
  }
  
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_val = $class_att->getType()->getValues()->[0];
  
  return [$row,$class_val];
}

sub initializeWuvMatrix {
  my ($self) = @_;
  
  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();
  my $WuvMatrix = zeroes $num_atts,$num_atts;
  
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      for (my $node_v = $node_u+1 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    my $lnWuv =  $self->CalculateLnWuvConstant($node_u,$node_v);
	    if ($self->getMarinaMeilaFormula())
	      {
		$lnWuv = 0;
	      }
	    #print "Wuv constant($node_u,$node_v) = $lnWuv\n";
	    $WuvMatrix->set($node_u,$node_v,$lnWuv);
	    $WuvMatrix->set($node_v,$node_u,$lnWuv);
	  }
	}
      }
    }
  }
  $self->setWuvMatrix($WuvMatrix);
}

sub initializeArithmeticPrecision {
  my ($self) = @_;

  my $schema = $self->getSchema();
  my $class_attno = $schema->getClassPos();
  my $class_att = $schema->getAttributeByPos($class_attno);
  my $class_card = $class_att->getType()->getCardinality();
  my $num_atts = $schema->getNumAttributes();
  my $WuvMatrix = $self->getWuvMatrix;
  
  my $max = undef;
  my $min = undef;
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u != $class_attno) {
      for (my $node_v = $node_u+1 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v != $class_attno) {
	  if ($node_v != $node_u) {
	    my $lnWuv = $WuvMatrix->at($node_u,$node_v);
	    if (!defined $max || $max < $lnWuv)
	      {
		$max = $lnWuv;
	      }
	    if (!defined $min || $min > $lnWuv)
	      {
		$min = $lnWuv;
	      }
	  }
	}
      }
    }
  }
  my $maxDiff = abs($max - $min);
  my $precision = 2*(($maxDiff / log 2) + 30);
  #print "Max:$max Min:$min MaxDiff:$maxDiff Precision (in bits): $precision\n";
  ntl::RR_SetPrecision(($precision>64)?$precision:64);

  print "NTL precision fixed to:".ntl::RR_precision()."\n";
  #$self->setPrecision($precision);
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
 
sub predict {
  my ($self,$row_to_classify) = @_;

  my ($schema,$class_attno,$class_att,@class_values,$class_val,%ProbRR,%Prob,);

  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};

  foreach $class_val (@class_values) {
    $ProbRR{$class_val} = $self->CalculateValueProportionalToPClass($row_to_classify,$class_val);
  }
  
  # Normalization of probabilities & calculation of the most probable class
  foreach $class_val (@class_values)
    {
      #print "P($class_val) = ",ntl::RR_GetDoubleValue($ProbRR{$class_val}),",";
    }
  #print "\n After normalization:\n";

  my $sum = ntl::new_RR(); 
  my $max = 0;
  my $probMax = ntl::new_RR();
  foreach $class_val (@class_values) {
    if (ntl::RR_LessOrEqual($probMax,$ProbRR{$class_val})) {
      ntl::RR_SetValue($probMax,$ProbRR{$class_val});
      $max = $class_val;
    }
    ntl::RR_add($sum,$ProbRR{$class_val}); 
  }
  if ($sum != 0) {
    foreach $class_val (@class_values) {
      ntl::RR_div($ProbRR{$class_val}, $sum); 
    }
  } else {
    foreach $class_val (@class_values) {
      ntl::RR_SetDoubleValue($ProbRR{$class_val}, 1 / ($#class_values + 1)); 
    }
  }
  foreach $class_val (@class_values) {
    $Prob{$class_val} = ntl::RR_GetDoubleValue($ProbRR{$class_val});
    ntl::delete_RR($ProbRR{$class_val});
    #print "P($class_val) = ",$Prob{$class_val},",";
  }
  #print "\n";
  
  # Clean up memory
  ntl::delete_RR($probMax);
  ntl::delete_RR($sum);
  return ([\%Prob,$max]);
}

sub CalculateValueProportionalToPClass {
  my ($self,$row_to_classify,$class_val) = @_;

  # Construct matrix beta x W
  # Calculate W u,v for each attribute u,v
  
  my $schema = $self->getSchema();

  my ($lnW,$productNucs) = @{$self->CalculatelnWMatrixAndProductNucs($row_to_classify,$class_val)};
  
  #print "lnW: $lnW\n";
  
  #print "lnW2: $lnW2\n";
  my $factor = $self->getReductionFactor();
  $lnW = $lnW + $factor;

  # From here on we should work in high precission
  
  my $prob = $self->ComputeProb($lnW,$productNucs);

  ntl::delete_RR($productNucs);
  #my $det = $self->ComputeQDeterminant($W);
  #my $detlow = $self->ComputeQDeterminantWithLowPrecision($W);

  #print "det = $det, detlow = $detlow, productNucs=$productNucs\n";

  return $prob;
}

sub CalculatelnWMatrixAndProductNucs {
  my ($self,$row_to_classify,$class_val) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};
  
  #print "Row to classify:",join(",",@$row_to_classify)."\n";
  
  
  my $num_atts = $schema->getNumAttributes()-1;
  my $lnW = zeroes $num_atts,$num_atts;
  #my $lnW2 = zeroes  $num_atts,$num_atts;
  my $W = zeroes $num_atts,$num_atts;
  
  my $node_u_higher_than_class_attno = 0;
  my $productNucs = ntl::new_RR();
  ntl::RR_SetDoubleValue($productNucs,1);
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u == $class_attno) {
      $node_u_higher_than_class_attno = 1;
    } else {
      my $nQuoteU =  $self->getNQuoteUC($node_u);
      my $nU = $self->getCountTable()->getCountXClass($class_val,$node_u,$row_to_classify->[$node_u]);
      ntl::RR_mulDouble($productNucs , $nU + $nQuoteU);
      my $node_v_higher_than_class_attno = 0;
      for (my $node_v = 0 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v == $class_attno) {
	  $node_v_higher_than_class_attno = 1;
	} else {
	  if ($node_v != $node_u) {
	    #print "A $node_u, $node_v\n";
	    # Calculate W u,v
	    #my $lnWuv = $self->CalculateLnWuv($row_to_classify,$class_val,$node_u,$node_v);
	    my $lnWuv = $self->CalculateLnWuv2($row_to_classify,$class_val,$node_u,$node_v);
	    #$lnW->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),$lnWuv);
	    $lnW->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),$lnWuv);
	    #$W->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),exp($lnWuv));
	  }
	}
      }
    }
  }
  return [$lnW,$productNucs];
}

sub ComputeProb {
  my ($self,$lnW,$productNucs) = @_;

  my $det = $self->ComputeQDeterminant($lnW);
  ntl::RR_mul($det,$productNucs);
  
  return $det;
}


sub ComputeQDeterminant {
  my ($self,$lnW) = @_;

  my $schema = $self->getSchema();
  
  # Copy the matrix to a high precision one, and simultaneously make the Q transformation
  my $betas = $self->getBetaMatrix();

  my $m = ntl::new_mat_RR();
  my $QMatrixSize = $schema->getNumAttributes()-2;
  ntl::mat_RR_SetDims($m,$QMatrixSize,$QMatrixSize);

  # Copy the matrix
  my $RR = ntl::new_RR();
  my $tmp = ntl::new_RR();
  my $sumVecRR = ntl::new_vec_RR();
  ntl::vec_RR_SetLength($sumVecRR,$schema->getNumAttributes()-2); 
  ntl::RR_SetDoubleValue($RR,0);	
  for (my $node = 0 ; $node < $schema->getNumAttributes()-2 ; $node++) {
    ntl::vec_RR_SetElement($sumVecRR,$node,$RR);
  }
  for (my $node_u = 0 ; $node_u < $schema->getNumAttributes()-2 ; $node_u++) {
    for (my $node_v = 0 ; $node_v < $schema->getNumAttributes()-2 ; $node_v++) {
      if ($node_u == $node_v) 
	{
	  ntl::RR_SetDoubleValue($RR,0);
	}
      else
	{
	  ntl::RR_SetDoubleValue($tmp,$lnW->at($node_u,$node_v));
	  ntl::RR_exp($RR,$tmp);
	  ntl::RR_mulDouble($RR,-($betas->at($node_u,$node_v)));
	}
      my $sumItem = ntl::vec_RR_GetElement($sumVecRR,$node_u);
      ntl::RR_sub($sumItem,$RR);
      ntl::mat_RR_SetElement($m,$node_u,$node_v,$RR);
    }
  }
  #ntl::delete_RR($RR);
  my $node_v = $schema->getNumAttributes()-2;
  for (my $node_u = 0 ; $node_u < $schema->getNumAttributes()-2 ; $node_u++) {
    ntl::RR_SetDoubleValue($tmp,$lnW->at($node_u,$node_v));
    ntl::RR_exp($RR,$tmp);
    ntl::RR_mulDouble($RR,-($betas->at($node_u,$node_v)));
    my $sumItem = ntl::vec_RR_GetElement($sumVecRR,$node_u);
    ntl::RR_sub($sumItem,$RR);
    ntl::mat_RR_SetElement($m,$node_u,$node_u,$sumItem);
  }
  
  #printMatrix($m);
  
  $RR = ntl::mat_RR_determinant($m);
  #print "Determinant exponent: ".ntl::RR_exponent($RR)."\n";
  ntl::delete_RR($tmp);
  ntl::delete_vec_RR($sumVecRR);
  ntl::delete_mat_RR($m);
  #my $det = ntl::RR_GetDoubleValue($RR);
   
  return $RR;
}

sub SumRow {
  my ($self,$m,$W,$node) = @_;

  my $RR = ntl::new_RR();
  ntl::RR_SetDoubleValue($RR,$W->at($node,$W->getdim(0)-1));
  for (my $i = 0 ; $i < $W->getdim(0)-1 ; $i++) {
    ntl::RR_sub($RR,ntl::mat_RR_GetElement($m,$node,$i));
  }
  return $RR;
}


sub printMatrix {
  my ($m) = @_;
  my $i = 0;
  my $j = 0;
  my $rows = ntl::mat_RR_NumRows($m);
  print "Number of rows is $rows\n";
  my $cols = ntl::mat_RR_NumCols($m);
  print "Number of columns is $cols\n";
  while ($i< $rows) {
    $j = 0;
    while ($j < $cols) {
      my $RR = ntl::mat_RR_GetElement($m,$i,$j);
      my $x = ntl::RR_GetDoubleValue($RR);
      print "Element $i,$j = $x\n";
      $j++;
    }
    $i++;
  }
}

sub ComputeQDeterminantWithLowPrecision {
  my ($self,$W) = @_;
  
  # Compute the sum for every row:
  my $schema = $self->getSchema();

  # print "betas*W=$W\n";
  my $WSum = dsumover $W;

  $W = -$W;
  for (my $node = 0 ; $node < $schema->getNumAttributes()-1 ; $node++) {
    $W->set($node,$node,$WSum->at($node));
  }

  #print "W size is :".$W->getdim(0)." x ".$W->getdim(1)."\n";
  
  my $d0=$W->getdim(0)-2;
  my $d1=$W->getdim(0)-2;
  
  my $finalW = $W->slice("0:$d0,0:$d1");

  #print "Imprecise matrix to calculate determinant: $finalW\n";
  #print "finalW size is :".$finalW->getdim(0)." x ".$finalW->getdim(1)."\n";
  
  #print "W(1,2) = ".$W->at(1,2)." and W(2,1)=".$W->at(2,1)."\n";
  #if ((abs($W->at(1,2)-$W->at(2,1)) / $W->at(1,2))>0.01) {
  #  die "There are big differences in W calculation\n";
  #}

  #
  my $det = det $finalW;
 # print "det = $det, productNucs=$productNucs\n";
  return $det;
}

sub  CalculateLnWuv{
  my ($self,$row_to_classify,$class_val,$node_u,$node_v) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};
  
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
	my $beta = 0;
	if (($row_to_classify->[$node_u] eq $u_val) && 
	    ($row_to_classify->[$node_v] eq $v_val) && 
	    ($class_val eq $class_val_iter)) {
	  $beta++;
	  #print "Adding one to this because $node_u equals $u_val and $node_v equals $v_val and class is $class_val_iter. Count= $count\n";
	}
	my $nquote = $self->getNQuoteUVC($node_u,$node_v);
	my $lnGamma = Math::Gsl::Sf::lngamma($count+$nquote+$beta);
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
      my $beta = 0;
      if (($row_to_classify->[$node_u] eq $u_val) &&
	  ($class_val eq $class_val_iter)) {
	$beta++;
	##print "Adding one to this because $node_u equals $u_val and class is $class_val_iter. Count=$count\n";
      }
      my $lnGamma = Math::Gsl::Sf::lngamma($count+$nquote+$beta);
      
      #print "LnGamma($count+$nquote+$beta)=$lnGamma\n";
      $lnWuv = $lnWuv - $lnGamma;
      
      # And now the N'uc
      
      $lnGamma =Math::Gsl::Sf::lngamma($nquote);
      $lnWuv = $lnWuv + $lnGamma;
    }
    $nquote = $self->getNQuoteUC($node_v);
    foreach my $v_val (@v_values) {
      my $count = $ct->getCountXClass($class_val_iter,$node_v,$v_val);
      my $beta = 0;
      if (($row_to_classify->[$node_v] eq $v_val) &&
	  ($class_val eq $class_val_iter)) {
	$beta++;
	#print "Adding one to this because $node_v equals $v_val and class is $class_val_iter. Count=$count\n";
      }
      my $lnGamma =Math::Gsl::Sf::lngamma($count+$nquote+$beta);
      #print "LnGamma($count+$nquote+$beta)=$lnGamma\n";
      $lnWuv = $lnWuv - $lnGamma;
      
      # And now the N'uc
      
      $lnGamma =Math::Gsl::Sf::lngamma($nquote);
      $lnWuv = $lnWuv + $lnGamma;
    }
  }
  return $lnWuv;
}

sub  CalculateLnWuvConstant{
  my ($self,$node_u,$node_v) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};
  
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

sub  CalculateLnWuv2 {
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

	   

sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

1;
