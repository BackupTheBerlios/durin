package Durin::ProbClassification::ProbApprox::PATANModel;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{COUNTTABLE} = undef; 
    $self->{LAMBDA} = $self->getLambda();
    $self->{GAMMA} = $self->getGamma();
    
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::ProbApprox::PAFG clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub getLambda {
  return 10;
}

sub getGamma {
  return 0.01;
}


sub setCountTable
  {
    my ($self,$ct) = @_;
    
    $self->{COUNTTABLE} = $ct;
    my $att;
    for ($att = 0 ; $att <  $self->{COUNTTABLE}->getNumAtts() ; $att++)
      {
	#print "A\n";
	my @attValues =  @{$self->{COUNTTABLE}->getAttValues($att)};
	#print "B\n";
	foreach my $value (@attValues)
	  {
	    $self->{COUNTX}[$att]{$value} = 0;
	  }
      }
    
    for ($att = 0 ; $att < $self->{COUNTTABLE}->getNumAtts() ; $att++)
      {
	#print "B, $att\n";
	#if ($att != $self->{COUNTTABLE}->getClassIndex())
	#  {
	my @attValues = @{$self->{COUNTTABLE}->getAttValues($att)};
	foreach my $value (@attValues)
	  {
	    foreach my $classVal (@{$self->{COUNTTABLE}->getClassValues()})
	      {
		#print "Att = $att, Val = $value\n";
		#print "ClassVal: $classVal, $att, $value :".$self->{COUNTTABLE}->getCountXClass($classVal,$att,$value)."\n";
		$self->{COUNTX}[$att]{$value} += $self->{COUNTTABLE}->getCountXClass($classVal,$att,$value);
	      }
	  }
	#  }
      }


    # Precomputing probabilities
    
    my $gamma = $self->{GAMMA};
    my $lambda = $self->{LAMBDA};

    # Initialize the array containing totals
    
    for (my $attX = 0 ; $attX <  $self->{COUNTTABLE}->getNumAtts() ; $attX++) {	
      $self->{PINDTOTX}[$attX] = 0;
      $self->{PTOTX}[$attX] = 0;
      for (my $attY = $attX+1 ; $attY <  $self->{COUNTTABLE}->getNumAtts() ; $attY++) {	
	$self->{PINDTOTXY}[$attX][$attY] = 0;
	$self->{PTOTXY}[$attX][$attY] = 0;
      }
    }

    # Precompute independent approximations
    
    my $cntTot = $self->{COUNTTABLE}->getCount();
    for (my $attX = 0 ; $attX <  $self->{COUNTTABLE}->getNumAtts() ; $attX++) {	
      my $cardX = $self->{COUNTTABLE}->getNumAttValues($attX);
      my @attXValues = @{$self->{COUNTTABLE}->getAttValues($attX)};
      foreach my $attXVal (@attXValues) {
	my $cntX = $self->{COUNTX}[$attX]{$attXVal};
	#print "cntX = $cntX\n";
	foreach my $classVal (@{$self->{COUNTTABLE}->getClassValues()}) {
	  my $cardClass = $self->{COUNTTABLE}->getNumClasses();
	  my $cntClass = $self->{COUNTTABLE}->getCountClass($classVal);
	  
	  my $numX = ($cntClass + ($gamma / $cardClass)) * ($cntX + ($gamma / $cardX));
	  my $denomX = ($cntTot + $gamma) * ($cntTot + $gamma);
	  
	  $self->{PINDXCLASS}[$attX]{$attXVal}{$classVal} = ($numX / $denomX);
	  $self->{PINDTOTX}[$attX] += $self->{PINDXCLASS}[$attX]{$attXVal}{$classVal};
	  
	  for (my $attY = $attX+1 ; $attY <  $self->{COUNTTABLE}->getNumAtts() ; $attY++) {	
	    my $cardY = $self->{COUNTTABLE}->getNumAttValues($attY);
	    my @attYValues = @{$self->{COUNTTABLE}->getAttValues($attY)};
	    foreach my $attYVal (@attYValues) {
	      #print "attY = $attY   attYVal = $attYVal\n";
	      my $cntY = $self->{COUNTX}[$attY]{$attYVal};
	      
	      if (!defined($cntY)) { die "Morí\n"};
	      #print "cntY = $cntY\n";
	      my $numXY = $numX * ($cntY + ($gamma / $cardY));
	      my $denomXY = $denomX * ($cntTot + $gamma);
	      
	      $self->{PINDXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal} = ($numXY / $denomXY);
	      #print "PInd[$attX][$attXVal][$classVal][$attY][$attYVal] = ".$self->{PINDXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal}."\n";
	      $self->{PINDTOTXY}[$attX][$attY] += $self->{PINDXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal};
	    }
	  }
	}
      }
    }

    # Normalizing independent approximations (if needed)

    for (my $attX = 0 ; $attX <  $self->{COUNTTABLE}->getNumAtts() ; $attX++) {	
      if ($self->{PINDTOTX}[$attX] != 1) {
	#print "Warning the probability sum A is: ".$self->{PINDTOTX}[$attX]."\n";
      }
      for (my $attY = $attX+1 ; $attY <  $self->{COUNTTABLE}->getNumAtts() ; $attY++) {	
	if ($self->{PINDTOTXY}[$attX][$attY] != 1) {
	  #print "Warning the probability sum B is: ".$self->{PINDTOTX}[$attX]."\n";
	}
      }
    }
    
    # Precomputing probabilities

    for (my $attX = 0 ; $attX <  $self->{COUNTTABLE}->getNumAtts() ; $attX++) {	
      my @attXValues = @{$self->{COUNTTABLE}->getAttValues($attX)};
      foreach my $attXVal (@attXValues) {
	foreach my $classVal (@{$self->{COUNTTABLE}->getClassValues()}) {
	  my $cntXClass = $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal);
	  
	  my $numXClass = ($cntXClass + ($self->{PINDXCLASS}[$attX]{$attXVal}{$classVal} * $lambda));
	  my $denomXClass = ($cntTot + $lambda);
	  
	  $self->{PXCLASS}[$attX]{$attXVal}{$classVal} = ($numXClass / $denomXClass);
	  $self->{PTOTX}[$attX] += $self->{PXCLASS}[$attX]{$attXVal}{$classVal};
	  for (my $attY = $attX+1 ; $attY <  $self->{COUNTTABLE}->getNumAtts() ; $attY++) {	
	      my @attYValues = @{$self->{COUNTTABLE}->getAttValues($attY)};
	      foreach my $attYVal (@attYValues) {
		if (($attX != $self->{COUNTTABLE}->getClassIndex()) && ($attY != $self->{COUNTTABLE}->getClassIndex()))  {
		  
		  my $cntXYClass = $self->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
		  
		  my $numXYClass = ($cntXYClass + ($self->{PINDXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal} * $lambda));
		  my $denomXYClass = $cntTot + $lambda;
		  
		  $self->{PXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal} = ($numXYClass / $denomXYClass);
		  $self->{PTOTXY}[$attX][$attY] += $self->{PXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal};
		}
	      }
	    }
	}
      }
    }
    
    # Normalizing probabilities (if needed)
    my $class = $self->{COUNTTABLE}->getClassIndex();
    
    for (my $attX = 0 ; $attX <  $self->{COUNTTABLE}->getNumAtts() ; $attX++) {	
      if ($attX != $self->{COUNTTABLE}->getClassIndex())  {
	if (difeps($self->{PTOTX}[$attX],1)) {
	  print "Warning the probability sum for $attX (class is $class) is : ".$self->{PTOTX}[$attX]."\n";
	}
      }
      for (my $attY = $attX + 1 ; $attY <  $self->{COUNTTABLE}->getNumAtts() ; $attY++) {  
	if (($attX != $self->{COUNTTABLE}->getClassIndex()) && ($attY != $self->{COUNTTABLE}->getClassIndex()))  {
	  if (difeps($self->{PTOTXY}[$attX][$attY],1)) {
	    print "Warning the probability sum D for $attX,$attY (class is $class) is: ".$self->{PTOTXY}[$attX][$attY]."\n";
	  }
	}
      }
    }
  }

sub difeps {
  my ($a,$b) = @_;

  return (abs($a-$b) > 0.00000001);
}

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;

    my $lambda = $self->{LAMBDA};
    my $gamma = $self->{GAMMA};
    my $pindnum = $self->{COUNTTABLE}->getCountClass($classVal) + ($gamma / $self->{COUNTTABLE}->getNumClasses());
    my $pinddenom = $self->{COUNTTABLE}->getCount() + $gamma;
    my $pind = $pindnum/$pinddenom;
    my $num = $self->{COUNTTABLE}->getCountClass($classVal) + ($pind * $lambda);
    my $denom = $self->{COUNTTABLE}->getCount() + $lambda;
    #my $num = $self->{COUNTTABLE}->getCountClass($classVal);
    #my $denom = $self->{COUNTTABLE}->getCount();
    
    return ($num / $denom);
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;

    my $num = $self->getPXClass($classVal,$attX,$attXVal);
    my $denom = $self->getPClass($classVal);
    
    return ($num / $denom);
  }

sub getPYCondXClass
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;

    my $num = $self->getPXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
    my $denom = $self->getPXClass($classVal,$attX,$attXVal);
    
    return ($num / $denom);
  }

sub getCountXYClass {
  my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
  my $CXYClass;
  
  if ($attX > $attY) {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
    # print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
  } else {
    $CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
    # print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
  }
  return $CXYClass;
}
    

sub getPXClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    
    return $self->{PXCLASS}[$attX]{$attXVal}{$classVal};
  }
	
sub getPXYClass {
  my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
  my $PXYClass;
  
  if ($attX > $attY) {
    $PXYClass = $self->{PXYCLASS}[$attY]{$attYVal}{$classVal}[$attX]{$attXVal}
  } else {
    $PXYClass =  $self->{PXYCLASS}[$attX]{$attXVal}{$classVal}[$attY]{$attYVal};
  }
  return $PXYClass;
}

sub getDetails()
  {
    my ($class) = @_;
    
    return {"PAMarginals lambda"=> $class->getLambda(),
	    "PAMarginals gamma"=> $class->getGamma()};
  }
