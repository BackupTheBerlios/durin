package Durin::DataStructures::ContingencyTable;

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{SUM} = 0;
    $self->{SUMX} = {};
    $self->{SUMY} = {};
    $self->{TABLE} = {};
    
    #self->{PARENTSHASH} = {};
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    my @KX = keys %{$source->{TABLE}};
    foreach $X (@KX)
      {
	my @KY = keys %{$source->{TABLE}{$X}};
	foreach $Y (@KY)
	  {
	    $self->set($X,$Y,$source->get($X,$Y));
	  }
      }
    #    print "DataStructures::UGraph cloning not tested\n");
  }

sub set
  {
    my ($self,$X,$Y,$n) = @_;
    
    if (exists $self->{TABLE}{$X}{$Y})
      {
	my $old = $self->{TABLE}{$X}{$Y};
	$self->{SUMX}{$X} += ($n - $old);
	$self->{SUMY}{$Y} += ($n - $old);
	$self->{SUM} += ($n - $old);
      }
    else
      {
	if (exists $self->{SUMX}{$X})
	  {
	    $self->{SUMX}{$X} += $n;
	  }
	else
	  {
	    $self->{SUMX}{$X} = $n;
	  }
	if (exists $self->{SUMY}{$Y})
	  {
	    $self->{SUMY}{$Y} += $n;
	  }
	else
	  {
	    $self->{SUMY}{$Y} = $n;
	  }
	$self->{SUM} += $n;
      }
    $self->{TABLE}{$X}{$Y} = $n;
  }

sub get
  {
    my ($self,$X,$Y) = @_;
    
    return $self->{TABLE}{$X}{$Y};
  }

sub getEntropyX
  {
    my ($self) = @_;
       
    my $entropy = 0.0;
    my $N = $self->{SUM};
    my @KX = keys %{$self->{SUMX}};
    my @KY = keys %{$self->{SUMY}};
    my $ArityX = $#KX + 1;
    my $ArityY = $#KY + 1;
    my $lambda = 50;
    # $self->print();
    foreach my $X (@KX)
      {
	my $entropyThisX = 0.0; 
	my $sumX = $self->{SUMX}{$X};
	#if ($sumX > 0)
	#  {
	#    print "X: $X, SumX: $sumX\n";
	foreach my $Y (@KY)
	  {
	    my $PXY;
	    # print "X: $X,Y: $Y\n";
	    #if (exists $self->{TABLE}{$X})
	    #  {
	    #    print "Exists\n";
	    #  }

	    
	    my $CXY;
	    if (exists $self->{TABLE}{$X}{$Y})
	      {
		$CXY = $self->{TABLE}{$X}{$Y};
	      }
	    else
	      {
		$CXY = 0;
	      }
	    $PXY = ($CXY + $lambda / ($ArityX * $ArityY)) / ($sumX + $lambda / $ArityX);
	    $entropyThisX -= $PXY * log2($PXY);
	  }
	#     }
	$entropy += ($sumX + $lambda/$ArityX)  * $entropyThisX / ($N + $lambda);
      }
    return $entropy;
  }

sub getEntropyOld
  {
    my ($self) = @_;
    
    my $entropy = 0.0;
    my $N = $self->{SUM};
    my @KY = keys %{$self->{SUMY}};
    my @KX = keys %{$self->{SUMX}};
    #    $self->print();
    foreach $X (@KX)
      {
	my $entropyThisX = 0.0; 
	my $sumX = $self->{SUMX}{$X};
	if ($sumX > 0)
	  {
	    #    print "X: $X, SumX: $sumX\n";
	    foreach $Y (@KY)
	      {
		my $FrequencyXY = $self->{TABLE}{$X}{$Y} / $sumX;
		if ($FrequencyXY > 0)
		  {
		    $entropyThisX -= $FrequencyXY * log2($FrequencyXY);
		  }
	      }
	    $entropy += $sumX * $entropyThisX / $N;
	  }
      }
    return $entropy;
  }

# Returns significance in Fayyad and Irani's terms.
sub isSignificant
  { 
    my ($self) = @_;
    
    my $N = $self->{SUM};
    my $entropy = 0.0;
    my @KY = keys %{$self->{SUMY}};
    my $ArityY = $#KY + 1;
    my $lambda = 10;
    foreach $Y (@KY)
      {
	my $FrequencyY = ($self->{SUMY}{$Y} + $lambda / $ArityY)/ ($N + $lambda) ;
	$entropy -= $FrequencyY * log2($FrequencyY);
      }
    my $costNT = ($N + $ArityY) * $entropy;
    my $costHT = log2($N-1) + log2(exp($ArityY * log(3)) - 2);
    my @KX = keys %{$self->{SUMX}};
    my $ArityX = $#KX + 1;
    foreach $X (@KX)
      {
	my $entropyThisX = 0.0; 
	my $sumX = $self->{SUMX}{$X};
	my $kj = 0;
	foreach $Y (@KY)
	  {
	    my $FrequencyXY = ($self->{TABLE}{$X}{$Y} + $lambda/($ArityX * $ArityY)) / ($sumX + $lambda / $ArityX);
	    $kj++;
	    $entropyThisX -= $FrequencyXY * log2($FrequencyXY);
	  }
	$costHT += ($kj + $sumX) * $entropyThisX;
      }   
    #print "cost HT: $costHT, costNT: $costNT\n";
    return ($costHT < $costNT);
  }

sub isSignificantOld
  { 
    my ($self) = @_;
    
    my $N = $self->{SUM};
    my $entropy = 0.0;
    my @KY = keys %{$self->{SUMY}};
    my $ArityY = $#KY + 1;
    my $lambda = 50;
    foreach $Y (@KY)
      {
	my $FrequencyY = ($self->{SUMY}{$Y} + $lambda / $ArityY)/ ($N + $lambda) ;
	if ($FrequencyY > 0)
	  {
	    $entropy -= $FrequencyY * log2($FrequencyY);
	  }
      }
    my $numClasses = $#KY + 1;
    my $costNT = ($N + $numClasses) * $entropy;
    my $costHT = log2($N-1) + log2(exp($numClasses * log(3)) - 2);
    my @KX = keys %{$self->{SUMX}};
    foreach $X (@KX)
      {
	my $entropyThisX = 0.0; 
	my $sumX = $self->{SUMX}{$X};
	my $kj = 0;
	foreach $Y (@KY)
	  {
	    my $FrequencyXY = $self->{TABLE}{$X}{$Y} / $sumX;
	    if ($FrequencyXY > 0)
	      {
		$kj++;
		$entropyThisX -= $FrequencyXY * log2($FrequencyXY);
	      }
	  }
	$costHT += ($kj + $sumX) * $entropyThisX;
      }   
    #print "cost HT: $costHT, costNT: $costNT\n";
    return ($costHT < $costNT);
  }


sub print
  {
    my ($self) = @_;
    
    my @KY = keys %{$self->{SUMY}};
    my @KX = keys %{$self->{SUMX}};
    foreach $X (@KX)
      {
	foreach $Y (@KY)
	  {
	    print "$X,$Y = ",$self->{TABLE}{$X}{$Y},"\n";;
	  }
      }   
  }

sub log2
  {
    my ($x) = @_;

    return log($x)/log(2);
  }
