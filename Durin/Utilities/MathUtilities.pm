package Durin::Utilities::MathUtilities;

sub log2
  {
    my ($x) = @_;
    
    return log($x) / log(2);
  }

sub log10
  {
    my ($x) = @_;
    
    return log($x) / log(10);
  }

sub Average
  {
    my ($v) = @_;

    my $sum = 0;
    my $i=0;
    foreach my $x (@$v)
      {
	$sum += $x;
	$i++;
      }
    return $sum/$i;
  }

sub StDev
  {
    my ($Av,$L) = @_;
    
    my $sum = 0.0;
    my @XL = @$L;
    #print "Average: $Av. List:",join (",",@XL),"\n";
    foreach $x (@XL)
      {
	$sum += ($x - $Av) * ($x - $Av);
      }
    #print "StDev: ",sqrt($sum / ($#XL + 1)),"\n";
    return sqrt($sum / ($#XL + 1));
  }

sub logfact
  {
    my ($n) = @_;
#    print "n:$n\n";
    if ($n != 0)
      {
	my $a1 = log(sqrt(2*3.141592654*$n));
	my $a2 = $n * log($n);
	my $a3 = (-$n);
	my $a4 = log(1 + (1/(12*$n)) + (1/(288 * $n *$n)) - (139/ (51840 * $n * $n * $n)));
    
	return ($a1 + $a2 + $a3 + $a4);
      }
    else
      {
	return log(1);
      }
  }

sub logbinom  
  {
    my ($N,$n) = @_;
    
    return logfact($N) - logfact($n) -logfact($N - $n); 
  }

sub max
  {
    my ($a,$b) = @_;
    
    if ($a > $b)
      {
	return $a;
      }
    else
      {
	return $b;
      }
  }
sub min
  {
    my ($a,$b) = @_;
    
    if ($a < $b)
      {
	return $a;
      }
    else
      {
	return $b;
      }
  }

1;
