package Durin::Math::Summation;

#use Durin::Utilities::MathUtilities;
#use POSIX;

sub SeriesSum
  {
    my ($start,$end,$maxEvals,$function) = @_;

    #    print "Started\n";
    
    my $sum = 0;
    my $intervalSize = $end - $start + 1;
    if ($intervalSize <= $maxEvals)
      {
	my $a;
	for (my $R = $start ; $R <= $end ; $R++)
	  {
	    #print "R:$N,$R,$n,$r\n";
	    $a = &$function($R);
	    #	print $R." ".$a."\n";
	    $sum += $a;
	  }
      }
    else
      { 
	my $step = $intervalSize/$maxEvals;
	my $startIndex = $start;
	my $startValue = &$function($startIndex);
	my $endIndex = int($start + $step);
	my $stepSize = $endIndex - $startIndex - 1;
	my $endValue;
	my $area = 0;
        $sum = $startValue;
	my $k = 1;
	
	while ($endIndex <= $end)
	  {
	    $endValue = &$function($endIndex);
	    $area = $endValue + ($stepSize * ($endValue + $startValue)/2);
	    
	    #print "Ar:$area , EV:$endValue, Step: $stepSize\n";
	    $sum += $area;
	    $startIndex = $endIndex;
	    $startValue = $endValue;
	    $k++;
	    $endIndex = int($start + $k * $step);
	    $stepSize = $endIndex - $startIndex - 1;
	    #print "$stepSize\n ";
	  }
	# Add the last triangle
	if ($startIndex <= $end)
	  {
	    $endValue = &$function($end);
	    my $lastStep = ($end - $startIndex - 1);
	    $area = $endValue + ($lastStep * ($endValue + $startValue)/2);
	    $sum += $area;
	  }
	#print "Ended\n";
      }
    return $sum;
  }
1;
