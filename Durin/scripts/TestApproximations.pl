#!/usr/bin/perl -w

# This scripts tests 3 ways of approximating probabilities in a 2 way contingency table.

use strict;

# Set the parameters

# Number of instances to generate

my $N = 2;

# Cardinality of attribute A

my $cardA = 3;

# Cardinality of attribute B

my $cardB = 3;

# Number of runs

my $numRuns = 500;

# Lambda

my $lambda = 10;

# Gamma

my $gamma = 100;



my ($p,$dat,$appF,$appL,$appLG,$appLGFG,$cF,$cL,$cLG,$cLGFG,$totF,$totL,$totLG,$totLGFG,$mF,$mL,$mLG,$mLGFG,$totMF,$totML,$totMLG,$totMLGFG,$cnt);

my ($appLG2,$cLG2,$totLG2,$mLG2,$totMLG2);

$totF = 0;
$totL = 0;
$totLG = 0;
$totLGFG = 0;
$totMF = 0;
$totML = 0;
$totMLG = 0;
$totMLGFG = 0;

$totLG2 = 0;
$totMLG2 = 0;

for (my $i = 0; $i <$numRuns  ; $i++) {
  #$p = generateDistrib($cardA,$cardB);
  $p = generateIndepDistrib($cardA,$cardB);
  print "Real distribution:\n";
  printDistrib($p,$cardA,$cardB);
  $dat = generateDataset($p,$N,$cardA,$cardB);
  $cnt = countDataset($dat,$cardA,$cardB);
  $appF = freqApprox($cnt,$cardA,$cardB);
  print "Frequency:\n";
  printDistrib($appF,$cardA,$cardB);
  #$cF = compareDistrib($appF,$p,$cardA,$cardB);
  $appL = lambdaApprox($cnt,$cardA,$cardB,$lambda);
  print "Lambda:\n";
  printDistrib($appL,$cardA,$cardB);
  #print "Comparing Lambda\n";
  $cL = compareDistrib($appL,$p,$cardA,$cardB);
  #print "Constructing Lambda-Gamma\n";
  $appLG = lambdaGammaApprox1($cnt,$cardA,$cardB,$lambda,$gamma);
  print "Lambda-Gamma:\n";
  printDistrib($appLG,$cardA,$cardB);
  #print "Comparing Lambda-Gamma\n";
  $cLG = compareDistrib($appLG,$p,$cardA,$cardB); 
  $appLGFG = lambdaGammaFGApprox($cnt,$cardA,$cardB,$lambda,$gamma);
  print "Lambda-Gamma-FG:\n";
  printDistrib($appLGFG,$cardA,$cardB);
  #print "Comparing Lambda-Gamma\n";
  $cLGFG = compareDistrib($appLGFG,$p,$cardA,$cardB);

  #$mF = compareBConditional($appF,$p,$cardA,$cardB);
  $mL = compareBConditional($appL,$p,$cardA,$cardB);
  $mLG = compareBConditional($appLG,$p,$cardA,$cardB);
  $mLGFG = compareBConditional($appLGFG,$p,$cardA,$cardB);
  
  #$totF += $cF;
  $totL += $cL;
  $totLG += $cLG; 
  $totLGFG += $cLGFG; 
  
  #$totMF += $mF;
  $totML += $mL;
  $totMLG += $mLG;
  $totMLGFG += $mLGFG;

  $appLG2 = lambdaGammaApprox2($cnt,$cardA,$cardB,$lambda,$gamma);
  print "Lambda-Gamma-2:\n";
  printDistrib($appLG2,$cardA,$cardB);
  $cLG2 = compareDistrib($appLG2,$p,$cardA,$cardB);
  $mLG2= compareBConditional($appLG2,$p,$cardA,$cardB);
  $totLG2 += $cLG2; 
  $totMLG2 += $mLG2;

  #print "Distance freq: $cF\n";
  #print "Distance lambda: $cL\n";
  #print "Distance lambda-gamma: $cLG\n";

}

print "F: $totF L: $totL L-G: $totLG L-GFG: $totLGFG L-G2:$totLG2\n";
print "MF: $totMF ML: $totML ML-G: $totMLG ML-GFG: $totMLGFG ML-G2:$totMLG2\n";

sub generateDistrib {
  my ($cardA,$cardB) = @_;
  
  # Create probability distribution
  #print "Generating probability distribution\n";
  my $p = [];
  my $thisP;
  my $total = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++) {
      $thisP = exp(exp(exp(rand 1)));
      $p->[$i][$j] = $thisP;
      $total = $total + $thisP;
    }
  }
  my $psum = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $thisP = $p->[$i][$j] / $total;
      $p->[$i][$j] = $thisP
    }
  }
  return $p;
}

sub generateIndepDistrib {
  my ($cardA,$cardB) = @_;
  
  # Create probability distribution
  #print "Generating probability distribution\n";
  my $p = [];
  my $pA = generateUniformMultinomial($cardA);
  #print "Now B\n";
  my $pB = generateUniformMultinomial($cardB);

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++) {
      $p->[$i][$j] = (($pA->[$i]) * ($pB->[$j]));
    }
  }
  return $p;
}

sub generateUniformMultinomial {
  my ($card) = @_;

  my $thisP;
  my $total = 0;
  # Generate probabilities 
  my $p = [];
  for (my $i = 0 ; $i < $card ; $i++) {
    $thisP = exp(exp(exp(rand 1));
    $p->[$i] = $thisP;
    $total = $total + $thisP;
  }
  
  # Normalize probabilities
  
  for (my $i = 0 ; $i < $card ; $i++) {
    $p->[$i] = $p->[$i]/$total;
    #print "Marginal $i = ".$p->[$i]."\n";
  }

  return $p;
}



sub generateDataset {
  my ($p,$N,$cardA,$cardB) = @_;

  my $thisP;
  my $pForSampling = [];
  my $psum = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $thisP = $p->[$i][$j];
      $psum = $psum + $thisP;
      $pForSampling->[$i][$j] = $psum;
    }
  }
  #print "Sampling from the distribution\n";
  my $dat = [];
  for (my $i = 0; $i < $N ; $i++) {
    my $pair = sample($pForSampling,$cardA,$cardB);
    push @$dat,$pair;
  }
  return $dat;
}

sub sample {
  my ($p,$cardA,$cardB) = @_;
  
  my $r = rand 1;
  my $found = 0;
  my $i = 0;
  my $j;
  
  while (($i < $cardA) && !$found) {
    $j = 0;
    while (($j < $cardB) && !$found) {
      $found = ($p->[$i][$j] >= $r);
      if (!$found) {
	$j++;
      }
    }
    if (!$found) {
      $i++;
    }
  }
  return [$i,$j];
}

sub freqApprox {
  my ($cnt,$cardA,$cardB) = @_;
  
  my $p = [];
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $p->[$i][$j] = $cntAB->[$i][$j]/$cntTot;
    }
  }
  return $p;
}

sub lambdaApprox {
  my ($cnt,$cardA,$cardB,$lambda) = @_;
  
  my $p = [];
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = ($cntAB->[$i][$j] + $lambda/($cardA*$cardB));
      my $denom = $cntTot+$lambda;
      $p->[$i][$j] = $num/$denom;
    }
  }
  return $p;
}

# Improved lambda approximation based on marginals

sub lambdaGammaApprox1 {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = [];
  my $cntA = $cnt->{A};
  my $cntB = $cnt->{B};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  # Calculate marginals
  my $cntABind = 0;

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $cntABind = $cntABind + ($cntA->[$i]) * ($cntB->[$j]) / ($cntTot * $cntTot);
    }
  }
  
  my $pind = [];
  my $tot = 0;

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      #my $num = (($cntA->[$i] + ($gamma/$cardA)) * ($cntB->[$j] + ($gamma/$cardB))) / (($cntTot + $gamma) * ($cntTot + $gamma));
      my $num = (($cntA->[$i] * $cntB->[$j] / ($cntTot * $cntTot)) + ($gamma/($cardA * $cardB)));
      my $denom = $cntABind + $gamma; 
      $pind->[$i][$j] = $num / $denom;
      $tot += $pind->[$i][$j];
      #print "Pind $i $j = ".$pind->[$i][$j]."\n";
    }
  }
  print "Tot: $tot\n";
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
    
      $pind->[$i][$j] = $pind->[$i][$j]/$tot;
    }
  }

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = ($cntAB->[$i][$j] + $pind->[$i][$j] * $lambda);
      my $denom = $cntTot+$lambda;
      $p->[$i][$j] = $num/$denom;
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  return $p;
}

sub lambdaGammaApprox2 {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = [];
  my $cntA = $cnt->{A};
  my $cntB = $cnt->{B};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  # Calculate marginals
  my $cntABind = 0;

  #for (my $i = 0 ; $i < $cardA ; $i++) {
  #  for (my $j = 0 ; $j < $cardB ; $j++){
  #    $cntABind = $cntABind + ($cntA->[$i]) * ($cntB->[$j]) / ($cntTot * $cntTot);
  #  }
  #}
  
  my $pind = [];
  my $tot = 0;

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = (($cntA->[$i] + ($gamma/$cardA)) * ($cntB->[$j] + ($gamma/$cardB)));
      my $denom = (($cntTot + $gamma) * ($cntTot + $gamma));
      #my $num = (($cntA->[$i] * $cntB->[$i] / ($cntTot * $cntTot)) + ($gamma/($cardA * $cardB)));
      #my $denom = $cntABind + $gamma;
      $pind->[$i][$j] = $num/$denom;
      #($cntA->[$i] + ($gamma/$cardA)) * ($cntB->[$j] + ($gamma/$cardB))
      $tot += $pind->[$i][$j];
      #print "Pind $i $j = ".$pind->[$i][$j]."\n";
    }
  }
  print "Tot: $tot\n";
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
    
      $pind->[$i][$j] = $pind->[$i][$j]/$tot;
    }
  }

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = ($cntAB->[$i][$j] + $pind->[$i][$j] * $lambda);
      my $denom = $cntTot+$lambda;
      $p->[$i][$j] = $num/$denom;
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  return $p;
}

# Improved lambda approximation based on just one marginal

sub lambdaGammaFGApprox {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = [];
  my $cntA = $cnt->{A};
  my $cntB = $cnt->{B};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  # Calculate marginals
  my $cntABind = 0;

  #for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      #$cntABind = $cntABind + ($cntA->[$i]/$cntTot) * ($cntB->[$j]/$cntTot);
      $cntABind = $cntABind + ($cntB->[$j] + ($gamma/$cardB) /$cntTot);
    }
  # }
  
  my $pind = [];

  my $tot = 0;

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      #my $num = (($cntA->[$i]/$cntTot) * ($cntB->[$j]/$cntTot)) + $gamma/($cardA*$cardB);
      my $num = ($cntB->[$j] + ($gamma/$cardB)) / ($cntTot + $gamma);
      #	+ $gamma/($cardA * $cardB);
      #my $denom = $cntABind;
      #+ $gamma;
      $pind->[$i][$j] = $num;
      $tot += $pind->[$i][$j];
      #print "Pind $i $j = ".$pind->[$i][$j]."\n";
    }
  }

  print "Tot: $tot\n";
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
    
      $pind->[$i][$j] = $pind->[$i][$j]/$tot;
    }
  } 
  
  $tot = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = ($cntAB->[$i][$j] + $pind->[$i][$j] * $lambda);
      my $denom = $cntTot+$lambda;
      $p->[$i][$j] = $num/$denom;
      $tot += $p->[$i][$j];
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $p->[$i][$j] = $p->[$i][$j] / $tot;
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  
  return $p;
}

sub countDataset {
  my ($dat,$cardA,$cardB) = @_;

  my $cnt = {};
  my $cntTot = 0;
  my $cntA = [];
  my $cntB = [];
  my $cntAB = [];

  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $cntAB->[$i][$j] =0;
    }
    $cntA->[$i] = 0;
  }
  for (my $j = 0 ; $j < $cardB ; $j++){
    $cntB->[$j] = 0;
  }
  
  foreach my $obs (@$dat) {
    $cntTot++;
    $cntA->[$obs->[0]]++;
    $cntB->[$obs->[1]]++;
    $cntAB->[$obs->[0]][$obs->[1]]++;
  }
  $cnt->{A} = $cntA;
  $cnt->{B} = $cntB;
  $cnt->{AB} = $cntAB;
  $cnt->{TOT} = $cntTot;
  return $cnt;
}

sub  compareDistrib {
  my ($app,$p,$cardA,$cardB) = @_;
  return SumAbsDif($app,$p,$cardA,$cardB);
}

sub  SumAbsDif {
  my ($app,$p,$cardA,$cardB) = @_;
  
  my $absDif = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      #print "Real: ".$p->[$i][$j]." App: ".$app->[$i][$j]."\n";
      $absDif = $absDif + abs($p->[$i][$j] - $app->[$i][$j]);
    }
  }
  return $absDif;
}



sub LogScore {
  my ($app,$p,$cardA,$cardB) = @_;
  my $logScore = 0;
  my $eps = 0.0000001;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      if ($app->[$i][$j] != 0) {
	$logScore = $logScore + ($p->[$i][$j] * log ($p->[$i][$j] / $app->[$i][$j]));
      } else {
	$logScore = $logScore + ($p->[$i][$j] * log ($p->[$i][$j] / $eps));
	#print "Error horrible \n";
      }	
      #print $logScore."\n";
    }
  }
  return $logScore;
}

sub  compareDistrib2 {
  my ($app,$p,$cardA,$cardB) = @_;
  
  my $logScore = 0;
  my $eps = 0.00000000000000001;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      if ($app->[$i][$j] != 0) {
	$logScore = $logScore + ($app->[$i][$j] * log ($app->[$i][$j] / $p->[$i][$j]));
      } else {
	$logScore = $logScore + ($eps * log ($eps / $p->[$i][$j]));
	#print "Error horrible \n";
      }
      #print $logScore."\n";
    }
  }
  return $logScore;
}

sub compareBConditional {
  my ($app,$p,$cardA,$cardB) = @_;

  # Calculate A-marginal

  my $appA = [];
  my $pA = [];
  for (my $i = 0 ; $i < $cardA ; $i++) {
    $appA->[$i] = 0;
    $pA->[$i] = 0;
    for (my $j = 0 ; $j < $cardB ; $j++){
      $appA->[$i] += $app->[$i][$j];
      $pA->[$i] += $p->[$i][$j];
    }
  }
  
  my $res = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    $res += compareThisBConditional($app,$p,$cardA,$cardB,$i,$appA->[$i],$pA->[$i]);
  }
  return $res;
}

sub compareThisBConditional {
  my ($app,$p,$cardA,$cardB,$i,$AMarg,$AMargReal) = @_;
  my $result = 0;
  my ($learnt,$real);
  
  if ($AMarg < 0.000001) {
    #print "JAJAJA Big mistake\n";
    $AMarg = 0.000001;
  }
  for (my $j = 0 ; $j < $cardB ; $j++) {
    $learnt = $app->[$i][$j] / $AMarg;
    $real = $p->[$i][$j] / $AMargReal;
    #print "$learnt -- $real\n";
    $result += compareProb($learnt,$real);
  }
  return $result;
}

sub compareProb {
  my ($learnt,$real) = @_;
  my $eps = 0.0000000000000001;
  if ($learnt != 0) {
    return $real * log($real/$learnt);
  } else {
    return $real * log($real/$eps);
  }
  #if ($learnt != 0) {
  #  return $learnt * log($learnt/$real);
  #} else {
  #  return $eps * log($eps/$real);
  #}
  #return abs($learnt-$real);
  #return ($learnt-$real)*($learnt-$real);
}

sub printDistrib {
  my ($p,$cardA,$cardB) = @_;
  
  my $tot = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      print "P[$i][$j] = ".$p->[$i][$j]."\n";
      $tot += $p->[$i][$j];
    }
  }
  if ($tot != 1) {
    print "************* Warning Total: $tot\n";
  }
}
