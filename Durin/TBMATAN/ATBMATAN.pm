package Durin::TBMATAN::ATBMATAN;

use base "Durin::TBMATAN::BaseTBMATAN";

use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;
use Math::Gsl::Sf;
use ntl;

use strict;
use warnings;

sub new_delta {
  my ($class,$self) = @_;
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
  die "Durin::TBMATAN::TBMATAN clone not implemented";
}

sub predict {
  my ($self,$row_to_classify) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob,);

  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};

  foreach $class_val (@class_values) {
    $Prob{$class_val} = $self->CalculateValueProportionalToPClass($row_to_classify,$class_val);
  }
  
  # Normalization of probabilities & calculation of the most probable class
  #foreach $class_val (@class_values)
  #  {
  #    print "P($class_val) = ",$Prob{$class_val},",";
  #  }
  #print "\n After normalization:\n";
  
  my $sum = 0; 
  my $max = 0;
  my $probMax = 0;
  foreach $class_val (@class_values) {
    if ($probMax<$Prob{$class_val}) {
      $probMax = $Prob{$class_val};
      $max = $class_val;
    }
    $sum += $Prob{$class_val};
  }
  if ($sum != 0) {
    foreach $class_val (@class_values) {
      $Prob{$class_val} = $Prob{$class_val}/$sum; 
    }
  } else {
    foreach $class_val (@class_values) {
      $Prob{$class_val} = 1 / ($#class_values + 1); 
    }
  }
  
  #foreach $class_val (@class_values)
  #  {
  #    print "P($class_val) = ",$Prob{$class_val},",";
  #  }

  
  return ([\%Prob,$max]);
}

sub CalculateValueProportionalToPClass {
  my ($self,$row_to_classify,$class_val) = @_;

  # Construct matrix beta x W
  # Calculate W u,v for each attribute u,v

  my $schema = $self->getSchema();

  my ($W,$productNucs) = @{$self->CalculateWMatrixAndProductNucs($row_to_classify,$class_val)};

  my $prob = $self->ComputeProb($W,$productNucs);

  return $prob;
}

sub CalculateWMatrixAndProductNucs {
  my ($self,$row_to_classify,$class_val) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};
  
  #print "Row to classify:",join(",",@$row_to_classify)."\n";
  
  my $num_atts = $schema->getNumAttributes()-1;
  my $W = zeroes $num_atts,$num_atts;
  
  my $node_u_higher_than_class_attno = 0;
  my $productNucs = 1;
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u == $class_attno) {
      $node_u_higher_than_class_attno = 1;
    } else {
      my $nQuoteU =  $self->getNQuoteUC($node_u);
      my $nU = $self->getCountTable()->getCountXClass($class_val,$node_u,$row_to_classify->[$node_u]);
      $productNucs *= ($nU + $nQuoteU);
      my $node_v_higher_than_class_attno = 0;
      for (my $node_v = 0 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v == $class_attno) {
	  $node_v_higher_than_class_attno = 1;
	} else {
	  if ($node_v != $node_u) {
	    #print "A $node_u, $node_v\n";
	    # Calculate W u,v
	    #my $lnWuv = $self->CalculateLnWuv($row_to_classify,$class_val,$node_u,$node_v);
	    my $lnWuv = $self->CalculateLogWuv($row_to_classify,$class_val,$node_u,$node_v);
	    #$lnW->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),$lnWuv);
	    #$lnW->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),$lnWuv);
	    $W->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),exp($lnWuv));
	  }
	}
      }
    }
  }
  return [$W,$productNucs];
}

sub ComputeProb {
  my ($self,$W,$productNucs) = @_;
  
  my $betas = $self->getBetaMatrix();
  $W = $W * $betas;

  my $det = $self->ComputeQDeterminant($W);
  #print "Det: $det, Nucs: $productNucs\n";
  $det *= $productNucs;
  
  return $det;
}

sub ComputeQDeterminant {
  my ($self,$W) = @_;

  my $schema = $self->getSchema();

  # Compute the sum for every row:
  
  my $WSum = dsumover $W;
  $W = -$W;
  for (my $node = 0 ; $node < $schema->getNumAttributes()-1 ; $node++) {
    $W->set($node,$node,$WSum->at($node));
  }
  
  #print "W size is :".$W->getdim(0)." x ".$W->getdim(1)."\n";
  
  my $d0=$W->getdim(0)-2;
  my $d1=$W->getdim(1)-2;

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
1;
