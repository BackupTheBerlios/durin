#!/usr/bin/perl -w

# This scripts tests 3 ways of approximating probabilities in a 2 way contingency table.

use strict;

# Set the parameters

# Number of instances to generate

my $N = 5;

# Cardinality of attribute A

my $cardA = 3;

# Cardinality of attribute B

my $cardB = 3;

# Number of runs

my $numRuns = 500;

# Lambda

my $lambda = 10;

# Gamma

my $gamma = 1;



my ($dat,$appF,$appL,$appLG,$appLGFG,$cF,$cL,$cLG,$cLGFG,$totF,$totL,$totLG,$totLGFG,$mF,$mL,$mLG,$mLGFG,$totMF,$totML,$totMLG,$totMLGFG,$cnt);

my ($p,$cB,$totB);
my ($appLG2,$cLG2,$totLG2,$mLG2,$totMLG2);




$totB = 0;
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
  
  # Generate distribution

  #$p = generateDistrib($cardA,$cardB);
  $p = generateIndepDistrib($cardA,$cardB);
  
  # Generate dataset and count it

  $dat = generateDataset($p,$N,$cardA,$cardB);
  $cnt = countDataset($dat,$cardA,$cardB);

  # Calculate Bayes error
  
  print "Real distribution:\n";
  printDistrib($p,$cardA,$cardB);
  $cB = compareClasifDistrib($p,$p,$cardA,$cardB);
  print "Bayes LogScore: $cB\n";
  $totB += $cB;

  # Calculate frequency error

  $appF = freqApprox($cnt,$cardA,$cardB);
  print "Frequency:\n";
  printDistrib($appF,$cardA,$cardB);
  $cF = compareClasifDistrib($appF,$p,$cardA,$cardB);
  $totF += $cF;

  # Calculate lambda error
  
  $appL = lambdaApprox($cnt,$cardA,$cardB,$lambda);
  print "Lambda:\n";
  printDistrib($appL,$cardA,$cardB);
  $cL = compareClasifDistrib($appL,$p,$cardA,$cardB);
  $totL += $cL;

  # Calculate lambda-gamma error
  
  $appLG = lambdaGammaApprox1($cnt,$cardA,$cardB,$lambda,$gamma);
  print "Lambda-Gamma:\n";
  printDistrib($appLG,$cardA,$cardB);
  $cLG = compareClasifDistrib($appLG,$p,$cardA,$cardB); 
  $totLG += $cLG;

  # Calculate lambda-gamma error 2
  $appLG2 = lambdaGammaApprox2($cnt,$cardA,$cardB,$lambda,$gamma);
  print "Lambda-Gamma-2:\n";
  printDistrib($appLG2,$cardA,$cardB);
  $cLG2 = compareClasifDistrib($appLG2,$p,$cardA,$cardB);
  $totLG2 += $cLG2;
  
  # Calculate FG error
  
  $appLGFG = lambdaGammaFGApprox($cnt,$cardA,$cardB,$lambda,$gamma);
  print "Lambda-Gamma-FG:\n";
  #printDistrib($appLGFG,$cardA,$cardB);
  $cLGFG = compareClasifDistrib($appLGFG,$p,$cardA,$cardB);
  $totLGFG += $cLGFG;
  
#  #$mF = compareBConditional($appF,$p,$cardA,$cardB);
#  $mL = compareBConditional($appL,$p,$cardA,$cardB);
#  $mLG = compareBConditional($appLG,$p,$cardA,$cardB);
#  $mLGFG = compareBConditional($appLGFG,$p,$cardA,$cardB);
  
#  #$totF += $cF;
#  $totL += $cL;
#  $totLG += $cLG; 
#  $totLGFG += $cLGFG; 
  
#  #$totMF += $mF;
#  $totML += $mL;
#  $totMLG += $mLG;
#  $totMLGFG += $mLGFG;

#  $appLG2 = lambdaGammaApprox2($cnt,$cardA,$cardB,$lambda,$gamma);
#  print "Lambda-Gamma-2:\n";
#  printDistrib($appLG2,$cardA,$cardB);
#  $cLG2 = compareDistrib($appLG2,$p,$cardA,$cardB);
#  $mLG2= compareBConditional($appLG2,$p,$cardA,$cardB);
#  $totLG2 += $cLG2; 
#  $totMLG2 += $mLG2;

  #print "Distance freq: $cF\n";
  #print "Distance lambda: $cL\n";
  #print "Distance lambda-gamma: $cLG\n";

}

print "Totals: Bayes:$totB Frequency:$totF Lambda: $totL Lambda-Gamma1:$totLG Lambda-Gamma2:$totLG2 FGLG:$totLGFG\n";
my $pB = $totB/$numRuns;
my $pF = $totF/$numRuns;
my $pL = $totL/$numRuns;
my $pLG = $totLG/$numRuns;
my $pLG2 = $totLG2/$numRuns;
my $pLGFG = $totLGFG/$numRuns;

print "Totals: Bayes:$pB Frequency:$pF Lambda: $pL Lambda-Gamma1:$pLG Lambda-Gamma2:$pLG2 FGLG:$pLGFG\n";

#print "F: $totF L: $totL L-G: $totLG L-GFG: $totLGFG L-G2:$totLG2\n";
#print "MF: $totMF ML: $totML ML-G: $totMLG ML-GFG: $totMLGFG ML-G2:$totMLG2\n";

sub generateDistrib {
  my ($cardA,$cardB) = @_;
  
  # Create probability distribution
  #print "Generating probability distribution\n";

  my $p = {};
  my $pAB = [];
  my $thisP;
  my $total = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++) {
      $thisP = exp(exp(exp(rand 1)));
      $pAB->[$i][$j] = $thisP;
      $total = $total + $thisP;
    }
  }
  my $psum = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $thisP = $pAB->[$i][$j] / $total;
      $pAB->[$i][$j] = $thisP
    }
  }
  $p->{AB} = $pAB;
  computeMarginalsAndConditionals($p,$cardA,$cardB);
  return $p;
}

sub generateIndepDistrib {
  my ($cardA,$cardB) = @_;
  
  # Create probability distribution
  #print "Generating probability distribution\n";
  my $p = {};
  my $pA = generateUniformMultinomial($cardA);
  #print "Now B\n";
  my $pB = generateUniformMultinomial($cardB);
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++) {
      $p->{AB}[$i][$j] = (($pA->[$i]) * ($pB->[$j]));
    }
  }
  computeMarginalsAndConditionals($p,$cardA,$cardB);
  return $p;
}

sub generateUniformMultinomial {
  my ($card) = @_;

  my $thisP;
  my $total = 0;
  # Generate probabilities 
  my $p = [];
  for (my $i = 0 ; $i < $card ; $i++) {
    $thisP = exp(exp(exp(rand 1)));
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
      $thisP = $p->{AB}[$i][$j];
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
  
  my $p = {};
  my $pAB = [];
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $pAB->[$i][$j] = $cntAB->[$i][$j]/$cntTot;
    }
  }

  $p->{AB} = $pAB;
  computeMarginalsAndConditionals($p,$cardA,$cardB);
  return $p;
}

sub computeMarginalsAndConditionals {
  my ($p,$cardA,$cardB) = @_;

  my $tot = [];
  # B given A

  for (my $j = 0 ; $j < $cardB ; $j++) {
    $p->{B}[$j] = 0;
  }
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    $p->{A}[$i] = 0;
    for (my $j = 0 ; $j < $cardB ; $j++) {
      $p->{A}[$i] += $p->{AB}[$i][$j]; 
      $p->{B}[$j] += $p->{AB}[$i][$j];
    }
  }
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++) {
      if ($p->{A}[$i] != 0) {
	$p->{BGIVENA}[$i][$j] = $p->{AB}[$i][$j] / $p->{A}[$i];
      } else {
	$p->{BGIVENA}[$i][$j] = 0;
      }
      if ($p->{B}[$j] != 0) {
	$p->{AGIVENB}[$i][$j] = $p->{AB}[$i][$j] / $p->{B}[$j];  
      }	else { 
	$p->{AGIVENB}[$i][$j] = 0;
      }
    }
  }
}

sub lambdaApprox {
  my ($cnt,$cardA,$cardB,$lambda) = @_;
  
  my $p = {};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = ($cntAB->[$i][$j] + $lambda/($cardA*$cardB));
      my $denom = $cntTot+$lambda;
      $p->{AB}[$i][$j] = $num/$denom;
    }
  }
  computeMarginalsAndConditionals($p,$cardA,$cardB);  
  return $p;
}

# Improved lambda approximation based on marginals

sub lambdaGammaApprox1 {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = {};
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
      $p->{AB}[$i][$j] = $num/$denom;
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  computeMarginalsAndConditionals($p,$cardA,$cardB);  
  return $p;
}

sub lambdaGammaApprox2 {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = {};
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
      $p->{AB}[$i][$j] = $num/$denom;
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  computeMarginalsAndConditionals($p,$cardA,$cardB);  
  return $p;
}

# Improved lambda approximation based on just one marginal

sub lambdaGammaFGApprox {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = {};
  my $cntA = $cnt->{A};
  my $cntB = $cnt->{B};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  for (my $j = 0 ; $j < $cardB ; $j++) {
    $p->{B}[$j] = ($cntB->[$j] + $lambda / $cardB)/ ($cntTot + $lambda);
  }
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = $cntAB->[$i][$j] + $lambda * $p->{B}[$j];
	#($cntB->[$j] + ($gamma / $cardB)) / ($cntTot + $gamma);
      my $denom = $cntA->[$i] + $lambda;
      
      $p->{BGIVENA}[$i][$j] = $num / $denom;
      
      $num = $cntAB->[$i][$j] + $lambda * ($cntA->[$i] + ($gamma / $cardA)) / ($cntTot + $gamma);
      $denom = $cntB->[$i] + $lambda;
      
      $p->{AGIVENB}[$i][$j] = $num / $denom;
    }
  }
  #computeMarginalsAndConditionals($p,$cardA,$cardB);    
  return $p;
}

sub lambdaGammaFGApprox2 {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = {};
  my $cntA = $cnt->{A};
  my $cntB = $cnt->{B};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  for (my $j = 0 ; $j < $cardB ; $j++) {
    $p->{B}[$j] = ($cntB->[$j] + $lambda / $cardB)/ ($cntTot + $lambda);
  }
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      my $num = $cntAB->[$i][$j] + $lambda * $p->{B}[$j];
	#($cntB->[$j] + ($gamma / $cardB)) / ($cntTot + $gamma);
      my $denom = $cntA->[$i] + $lambda;
      
      $p->{BGIVENA}[$i][$j] = $num / $denom;
      
      $num = $cntAB->[$i][$j] + $lambda * ($cntA->[$i] + ($gamma / $cardA)) / ($cntTot + $gamma);
      $denom = $cntB->[$i] + $lambda;
      
      $p->{AGIVENB}[$i][$j] = $num / $denom;
    }
  }
  #computeMarginalsAndConditionals($p,$cardA,$cardB);    
  return $p;
}

sub lambdaGammaFGApproxVeryGood {
  my ($cnt,$cardA,$cardB,$lambda,$gamma) = @_;
  
  my $p = {};
  my $cntA = $cnt->{A};
  my $cntB = $cnt->{B};
  my $cntAB = $cnt->{AB};
  my $cntTot = $cnt->{TOT};
  
  # Calculate marginals
  my $cntABind = 0;

  #for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      #$cntABind = $cntABind + ($cntA->[$i]/$cntTot) * ($cntB->[$j]/$cntTot);
      $cntABind = $cntABind + ($cntB->[$j] + ($gamma/$cardB) / $cntTot);
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
      $p->{AB}[$i][$j] = $num/$denom;
      $tot += $p->{AB}[$i][$j];
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
  
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      $p->{AB}[$i][$j] = $p->{AB}[$i][$j] / $tot;
      #print "PL-G $i $j = ".$p->[$i][$j]."\n";
    }
  }
 computeMarginalsAndConditionals($p,$cardA,$cardB);    
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

sub  compareClasifDistrib {
  my ($app,$p,$cardA,$cardB) = @_;
  return LogScore($app,$p,$cardA,$cardB);
}

sub LogScore {
  my ($app,$p,$cardA,$cardB) = @_;
  my $logScore = 0;
  # For each possible input add the probability that our 
  # classifier assigns to the most probable class.
  my $errorEsp = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    my $pError = $p->{A}[$i] * (1-PClass($app,$p,$cardA,$cardB,$i));
    if ($pError != 0) {
      $errorEsp += $pError;
    }
  }
  return $errorEsp;
}


sub PClass {
  my ($app,$p,$cardA,$cardB,$i) = @_;

  my $eps = 0.00000001;
  my $j = MostProbableClass($app,$cardB,$i);
  #my $j = $r->[0];
  my $probClass = $p->{BGIVENA}[$i][$j];
  #			  )$app->{B}[$j] * $app->{AGIVENB}[$i][$j]; 
  print "Most probable class for $i is $j and its probability is $probClass\n";
  if ($probClass == 0) {
    $probClass = $eps;
  }
  return $probClass;
}

# Given a probability distribution, it determines the 
# most probable class and its probability.

sub MostProbableClass {
  my ($app,$cardB,$i) = @_;
  
  my $jMax= 0;
  my $pMax = 0;
  
  foreach my $j (0..$cardB-1) {
    my $thisP = $app->{B}[$j] * $app->{AGIVENB}[$i][$j];
    if ($thisP > $pMax) {
      $pMax = $thisP;
      $jMax = $j;
    }
  }
  return $jMax;
}

sub calcProb {
  my ($app,$cardB,$i,$j) = @_;
  
  my $jMax= 0;
  my $pMax = 0;
  my $tot = 0;
  foreach my $j2 (0..$cardB-1) {
    my $thisP = $app->{B}[$j2] * $app->{AGIVENB}[$i][$j2];
    print "$i,$j2 -> $thisP\n";
    $tot += $thisP;
  }
  my $result;
  if ($tot!=0) {
    $result = $app->{B}[$j] * $app->{AGIVENB}[$i][$j] / $tot;
  }
  print "decided: $result\n";

  return $result;
}

sub printDistrib {
  my ($p,$cardA,$cardB) = @_;
  
  my $tot = 0;
  for (my $i = 0 ; $i < $cardA ; $i++) {
    for (my $j = 0 ; $j < $cardB ; $j++){
      print "P[$i][$j] = ".$p->{AB}[$i][$j]."\n";
      $tot += $p->{AB}[$i][$j];
    }
  }
  if ($tot != 1) {
    print "************* Warning Total: $tot\n";
  }
}
