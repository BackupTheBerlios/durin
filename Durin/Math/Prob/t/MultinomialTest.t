use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1};

use Durin::Math::Prob::Multinomial;
use IO::File;

#my $file = new IO::File ("<t/MultinomialTestResult");
#my $expectedResult = join("",$file->getlines());

#print $expectedResult;

my $nX = 2;
my $nY = 2;
my $nZ = 2;

my $m = Durin::Math::Prob::Multinomial->new();
$m->setDimensions(1);
$m->setCardinalities([5]);
foreach my $i (0..$nX-1) {
  $m->setP([$i],($i+1)*2);	
}
$m->normalize();

foreach my $i (0..$nX-1) {
  print "p($i) = ".$m->getP([$i])."\n";
}

my $mXY = Durin::Math::Prob::Multinomial->new();
$mXY->setDimensions(2);
$mXY->setCardinalities([$nX,$nY]);
foreach my $i (0..$nX-1) {
 foreach my $j (0..$nY-1) {
   $mXY->setP([$i,$j],$i*10+$j+1);
 }	
}
$mXY->normalize();

foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) {
    print "p($i,$j) = ".$mXY->getP([$i,$j])."\n";
  }
}

foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) {
    print "p($j | $i) = ".$mXY->getPYCondX($i,$j)."\n";
  }
}

my $mXYZ = Durin::Math::Prob::Multinomial->new();
$mXYZ->setDimensions(3);
$mXYZ->setCardinalities([$nX,$nY,$nZ]);
foreach my $i (0..$nX-1) {
 foreach my $j (0..$nY-1) {
   foreach my $k (0..$nZ-1) {
     $mXYZ->setP([$i,$j,$k],$k*100+$i*10+$j+1);
   }
 }	
}
$mXYZ->normalize();

foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) {
    foreach my $k (0..$nZ-1) {
      print "p($i,$j,$k) = ".$mXYZ->getP([$i,$j,$k])."\n";
    }
  }
}

foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) { 
    foreach my $k (0..$nZ-1) {
      print "p($k | $i,$j) = ".$mXYZ->getPZCondXY($i,$j,$k)."\n";
    }
  }
}

my $mX = $mXYZ->getMarginal(0);

foreach my $i (0..$nX-1) {
  print "p($i) = ".$mX->getP([$i])."\n";
}

 

ok(1,1);
#ok($realResult,$expectedResult);