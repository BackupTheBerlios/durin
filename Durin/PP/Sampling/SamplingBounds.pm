package Durin::PP::Sampling::SamplingBounds;

use Durin::Utilities::MathUtilities;
use Durin::Math::Summation;
use POSIX;


sub RProb
  {
     my ($N,$R,$n,$r) = @_;

     if ($R < $r)
       {
	 return 0;
       }
     if (($N-$R) < ($n-$r))
       {
	 return 0;
       }
     
     return exp(logRProb($N,$R,$n,$r));
   }
sub logRProb
  {
    my ($N,$R,$n,$r) = @_;
    
    return Durin::Utilities::MathUtilities::logbinom($R,$r) + Durin::Utilities::MathUtilities::logbinom($N-$R,$n-$r) -  Durin::Utilities::MathUtilities::logbinom($N+1,$n+1);
  }

sub MAPREst
  {
    my ($N,$n,$r) = @_;
    
    my $RP = ($N+1) * $r / $n;
    my $FRP = POSIX::floor($RP);
    if ($FRP != $RP)
      {
	return $FRP;
      }
    else
      {
	if ($FRP > $N)
	  {
	    return $N;
	  }
	else
	  {
	    return $FRP;
	  }
      }
  }
    
sub MAPFEst
  {
    my ($N,$n,$r) = @_;
    
    return (MAPREst($N,$n,$r)/$N);
    
#    my $RP = ($N+1) * $r / $n;
#    my $FRP = POSIX::floor($RP);
#    if ($FRP != $RP)
#      {
#	
#	return ($FRP/$N);
#      }
#    else
#      {
#	if ($FRP > $N)
#	  {
#	    return 1;
#	  }
#	else
#	  {
#	    return $FRP/$N;
#	  }
    #     }
  }

sub FEst
  {
    my ($N,$n,$r) = @_;
    
    return (($r+1)/($n+2)) + ((2 * $r - $n)/($N*($n + 2)));
  }

sub AddConfidence
  {
    my ($N,$n,$r,$eps) = @_;
    
    my $Fest = FEst($N,$n,$r);
    my $start = POSIX::ceil( Durin::Utilities::MathUtilities::max(($Fest - $eps) * $N,$r));
    my $end = POSIX::floor( Durin::Utilities::MathUtilities::min(($Fest + $eps) * $N,$N-$n+$r));

#    print "Fest = $Fest, Start: $start, End:$end \n";
  
    my $conf = 0;
    for (my $R = $start ; $R <= $end ; $R++)
      {
	my $a = exp(logRProb($N,$R,$n,$r));
#	print $R." ".$a."\n";
	$conf += $a;
      }
    return $conf;
  }

sub PriorCerquidesAddConfidence
  {
    my ($N,$n,$eps) = @_;
    
    return CerquidesAddConfidence($N,$n,int($n/2),$eps);
  }

    
sub CerquidesAddConfidence
  {
    my ($N,$n,$r,$eps) = @_;
    
    my $Fest = MAPFEst($N,$n,$r);
    my $start = POSIX::ceil( Durin::Utilities::MathUtilities::max(($Fest - $eps) * $N,$r));
    my $end = POSIX::floor( Durin::Utilities::MathUtilities::min(($Fest + $eps) * $N,$N-$n+$r));

    if ($end - $start < 0)
    {
      $start = $end;
    }
    # print "Fest = $Fest, Start: $start, End:$end \n";
  
    my $conf = 0;
    for (my $R = $start ; $R <= $end ; $R++)
      {
	#print "R:$N,$R,$n,$r\n";
	my $a = RProb($N,$R,$n,$r);
#	print $R." ".$a."\n";
	$conf += $a;
      }
    $conf = Durin::Utilities::MathUtilities::min($conf,1);
    print "Fest = $Fest, Start: $start, End:$end , Conf:$conf\n";
  
    return $conf;
  }

sub FastCerquidesAddConfidence
  {
    my ($N,$n,$r,$eps,$maxEvals) = @_;
    
    my $Fest = MAPFEst($N,$n,$r);
    my $start = POSIX::ceil( Durin::Utilities::MathUtilities::max(($Fest - $eps) * $N,$r));
    my $end = POSIX::floor( Durin::Utilities::MathUtilities::min(($Fest + $eps) * $N,$N-$n+$r)); 
    
    if ($end < $start)
      {
	$start = $end;
      }
    
    my $probFunction = sub
      {
	my ($R) = @_;
	
	return RProb($N,$R,$n,$r);
      };
    
    my $conf = Durin::Math::Summation::SeriesSum($start,$end,$maxEvals,$probFunction);
    
    $conf = Durin::Utilities::MathUtilities::min($conf,1);
    print "ConfFinal approx 1: $conf\n";
    return $conf;
  }


# This one works well for n/r ~= 0 o n/r ~= 1
sub FastCerquidesAddConfidence2
  {
    my ($N,$n,$r,$eps,$maxEvals) = @_;
    
    my $Fest = MAPFEst($N,$n,$r);
    my $start = POSIX::ceil( Durin::Utilities::MathUtilities::max(($Fest - $eps) * $N,$r));
    my $end = POSIX::floor( Durin::Utilities::MathUtilities::min(($Fest + $eps) * $N,$N-$n+$r)); 
    
    if ($end < $start)
      {
	$start = $end;
      }
    
    my $probFunction = sub
      {
	my ($R) = @_;
	
	return RProb($N,$R,$n,$r);
      };
  
    my $RPred = MAPREst($N,$n,$r);
    my $quarterEvals = int($maxEvals/4);
    my $startInterval = Durin::Utilities::MathUtilities::max($RPred-$quarterEvals,$start);
    my $endInterval = Durin::Utilities::MathUtilities::min($RPred+$quarterEvals,$end);
	
    my $conf = 0;
    for (my $R = $startInterval; $R <= $endInterval; $R++)
      {
	$conf += &$probFunction($R);
      }
    #print "ConfTemp: $conf\n";
    if ($startInterval > $start)
      {
	$conf += Durin::Math::Summation::SeriesSum($start,$startInterval-1,$quarterEvals,$probFunction);
      }
    if ($end > $endInterval)
      {
	$conf += Durin::Math::Summation::SeriesSum($endInterval+1,$end,$quarterEvals,$probFunction);
      }
    $conf = Durin::Utilities::MathUtilities::min($conf,1);
    print "ConfFinal approx 2: $conf\n";
    return $conf;
  }

sub FastCerquidesAddConfidence3
  {
    my ($N,$n,$r,$eps,$maxEvals) = @_;
    
    my $Fest = MAPFEst($N,$n,$r);
    my $start = POSIX::ceil( Durin::Utilities::MathUtilities::max(($Fest - $eps) * $N,$r));
    my $end = POSIX::floor( Durin::Utilities::MathUtilities::min(($Fest + $eps) * $N,$N-$n+$r)); 

    if ($end < $start)
    {
      $start = $end;
    }
    
    # print "Fest = $Fest, Start: $start, End:$end \n";
    # Here we have to apply integration techniques
    
    # We split into $maxEvals and integrate 
    my $conf = 0;
    my $intervalSize = $end - $start + 1;
    if ($intervalSize >= $maxEvals)
      {
	# We calculate everything except the interval, then 1 - x is the prob of the interval
        my $halfEvals = int($maxEvals/2);
	my $probFunction = sub
	  {
	    my ($R) = @_;
	    
	    return RProb($N,$R,$n,$r);
	  };

	my $confUpper = 0;
	my $confLower = 0;
	if ($start-1 >= $r+1)
	  {
	    $confLower = Durin::Math::Summation::SeriesSum($r+1,$start-1,$halfEvals,$probFunction);
	  }

	if ($N-$n+$r-1 >= $end+1)
	  { 
	    $confUpper = Durin::Math::Summation::SeriesSum($end+1,$N-$n+$r-1,$halfEvals,$probFunction);
	  }
	
	$conf = 1-$confLower-$confUpper;
	print "Conf: $conf, Lower: $confLower, Upper: $confUpper\n";
      }
    else
      {
	for (my $R = $start ; $R <= $end ; $R++)
	  {
	    #print "R:$N,$R,$n,$r\n";
	    my $a = RProb($N,$R,$n,$r);
	    #	print $R." ".$a."\n";
	    $conf += $a;
	  }
      }
    return $conf;
  }

sub ChernoffAddConfidence
  {
    my ($n,$eps) = @_;
    my $conf = 1 - 2 * exp(-2 * $n * $eps * $eps);
    
    return Durin::Utilities::MathUtilities::max($conf,0);
  }

sub ChernoffBound
  { 
    my ($C,$eps) = @_;

    if ($eps > 0)
      {
	return -int(log((1-$C)/2)/(2 * $eps * $eps));
      }
    else
      {
	return 1000000000000000000000000000;
      }
  }

sub CerquidesBound
  {
    my ($N,$C,$eps) = @_;

    my $min = 1;
    my $max = $N;
    my $found = 0;
    my $middle;
    while (!$found)
      {
	$middle = int(($min+$max)/2);
	if ($middle == $min)
	  {
	    $found = 1;
	  }
	else
	  {
	    $midC = PriorCerquidesAddConfidence($N,$middle,$eps);
	    if ($midC > $C)
	      {
		$max = $middle;
	      }
	    else
	      {
		$min = $middle;
	      }
	    print "[$min-$max]\n";
	  }
      }
    return $middle;
  }

1;
