package Durin::Math::Correlation;

use strict;
use Durin::Utilities::MathUtilities;

# given two vectors returns their correlation coeficient
sub correlation
  {
    my ($vx,$vy) = @_;
    
    my $i = 0;
    
    my $averagex = Durin::Utilities::MathUtilities::Average($vx);
    my $averagey = Durin::Utilities::MathUtilities::Average($vy);
    my $numerator = 0;  my $numeratorx = 0;my $numeratory = 0;
    my $sumsquarex = 0;
    my $sumsquarey = 0;
    my ($sx,$sy,$y);
    foreach my $x (@$vx)
      {
	$y = $vy->[$i];
	$sx = ($x-$averagex);
	$sy = ($y-$averagey);
	$numerator += $sx * $sy;
	$numeratorx += $sx;
	$numeratory += $sy;
	$sumsquarex += $sx*$sx;
	$sumsquarey += $sy*$sy;
	$i++;
      }
    my $r;
    if (($sumsquarey == 0) || ($sumsquarex == 0))
      {
	$r = 0;
      }
    else
      {	
	my $denominator = sqrt($sumsquarex * $sumsquarey);
	$r = ($numerator/$denominator);
	if ($r > 1)
	  {
	    $r = 1;
	  }
	else
	  {
	    if ($r < -1)
	      {
		$r = -1;
	      }
	  }
      }
    return $r;
  }

1;
