package Durin::TBMATAN::TBMATAN;

use Durin::Classification::Model;

use base "Durin::Classification::Model";

use Class::MethodMaker
  get_set => [ -java => qw/CountTable BetaMatrix/];


use Durin::Utilities::MathUtilities;

use PDL;
use PDL::Slatec;

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

sub predict {
  my ($self,$row_to_classify) = @_;
  
  my ($schema,$class_attno,$class_att,@class_values,$class_val,%Prob);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};
  
  foreach $class_val (@class_values) {
    $Prob{$class_val} = $self->CalculateValueProportionalToPClass($row_to_classify,$class_val);
  }
  
  # Normalization of probabilities & calculation of the most probable class
  foreach $class_val (@class_values)
    {
      print "P($class_val) = ",$Prob{$class_val},",";
    }
  print "\n After normalization:\n";
  my $sum = 0.0; 
  my $max = 0;
  my $probMax = 0.0;
  foreach $class_val (@class_values) {
    if ($probMax <= $Prob{$class_val}) {
      $probMax = $Prob{$class_val};
      $max = $class_val;
    }
    $sum += $Prob{$class_val}; 
  }
  if ($sum != 0) {
    foreach $class_val (@class_values) {
      $Prob{$class_val} = ($Prob{$class_val} / $sum); 
    }
  } else {
    foreach $class_val (@class_values) {
      $Prob{$class_val} = 1 / ($#class_values + 1); 
    }
  }
  foreach $class_val (@class_values) {
    print "P($class_val) = ",$Prob{$class_val},",";
  }
  print "\n";
  return ([\%Prob,$max]);
}

sub CalculateValueProportionalToPClass {
  my ($self,$row_to_classify,$class_val) = @_;

  # Construct matrix beta x W
  # Calculate W u,v for each attribute u,v
  
  my ($schema,$class_attno,$class_att,@class_values);
  
  $schema = $self->getSchema();
  $class_attno = $schema->getClassPos();
  $class_att = $schema->getAttributeByPos($class_attno);
  @class_values = @{$class_att->getType()->getValues()};
  
  print "Row to classify:",join(",",@$row_to_classify)."\n";

  my $num_atts = $schema->getNumAttributes()-1;
  my $W = zeroes $num_atts,$num_atts;
  
  my $node_u_higher_than_class_attno = 0;
  my $productNucs = 1;
  for(my $node_u = 0 ; $node_u < $schema->getNumAttributes() ; $node_u++) {
    if ($node_u == $class_attno) {
      $node_u_higher_than_class_attno = 1;
    } else {
      $productNucs = $productNucs * ($self->getCountTable()->getCountXClass($class_val,$node_u,$row_to_classify->[$node_u]) + 1);
      my $node_v_higher_than_class_attno = 0;
      for (my $node_v = 0 ; $node_v < $schema->getNumAttributes() ; $node_v++) {
	if ($node_v == $class_attno) {
	  $node_v_higher_than_class_attno = 1;
	} else {
	  if ($node_v != $node_u) {
	    # Calculate W u,v
	    my $logWuv = $self->CalculateLogWuv($row_to_classify,$class_val,$node_u,$node_v);
	    $W->set(($node_u - $node_u_higher_than_class_attno),($node_v - $node_v_higher_than_class_attno),exp($logWuv));
	  }
	}
      }
    }
  }
  
  print "$W\n";

  # We have calculated W. Let's do some checks

  #  print "W(1,2) = ".$W->at(1,2)." and W(2,1)=".$W->at(2,1)."\n";
  if ((abs($W->at(1,2)-$W->at(2,1)) / $W->at(1,2))>0.01) {
    die "There are big differences in W calculation\n";
  }
  
  my $betas = $self->getBetaMatrix();
  $W = $W * $betas;

  print "betas*W=$W\n";
  my $WSum = dsumover $W;

  $W = -$W;
  for (my $node = 0 ; $node < $schema->getNumAttributes()-1 ; $node++) {
    $W->set($node,$node,$WSum->at($node));
  }

  #print "W size is :".$W->getdim(0)." x ".$W->getdim(1)."\n";
  
  my $d0=$W->getdim(0)-2;
  my $d1=$W->getdim(0)-2;
  
  my $finalW = $W->slice("0:$d0,0:$d1");

  print "$finalW\n";
  #print "finalW size is :".$finalW->getdim(0)." x ".$finalW->getdim(1)."\n";
  
  #print "W(1,2) = ".$W->at(1,2)." and W(2,1)=".$W->at(2,1)."\n";
  if ((abs($W->at(1,2)-$W->at(2,1)) / $W->at(1,2))>0.01) {
    die "There are big differences in W calculation\n";
  }

  my $det = det $finalW;
  print "det = $det, productNucs=$productNucs\n";

  return $det*$productNucs;
}

sub  CalculateLogWuv{
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
  
  my $logWuv = 0;
  
  foreach my $class_val_iter (@class_values) {
    foreach my $u_val (@u_values) {
      foreach my $v_val (@v_values) {
	my $count = $ct->getCountXYClass($class_val_iter,$node_u,$u_val,$node_v,$v_val);
	
	if (($row_to_classify->[$node_u] eq $u_val) && 
	    ($row_to_classify->[$node_v] eq $v_val) && 
	    ($class_val eq $class_val_iter)) {
	  $count++;
	  print "Adding one to this because $node_u equals $u_val and $node_v equals $v_val and class is $class_val_iter. Count= $count\n";
	}
	my $logfact = Durin::Utilities::MathUtilities::logfact($count+1);
	#print "LogFact($count)=$logfact\n";
	$logWuv = $logWuv+$logfact;
      }
    }
    foreach my $u_val (@u_values) {
      my $count = $ct->getCountXClass($class_val_iter,$node_u,$u_val);
      
      if (($row_to_classify->[$node_u] eq $u_val) &&
	  ($class_val eq $class_val_iter)) {
	$count++;
	print "Adding one to this because $node_u equals $u_val and class is $class_val_iter. Count=$count\n";
      }
      my $logfact = Durin::Utilities::MathUtilities::logfact($count+1);
      #print "LogFact($count)=$logfact\n";
      $logWuv = $logWuv-$logfact;
    }
    foreach my $v_val (@v_values) {
      my $count = $ct->getCountXClass($class_val_iter,$node_v,$v_val);
      if (($row_to_classify->[$node_v] eq $v_val) &&
	  ($class_val eq $class_val_iter)) {
	$count++;
	print "Adding one to this because $node_v equals $v_val and class is $class_val_iter. Count=$count\n";
      }
      $logWuv = $logWuv-Durin::Utilities::MathUtilities::logfact($count+1);
    }
  }
  return $logWuv;
}



sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

1;
