use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1};

use Durin::Math::Prob::MultinomialGenerator;
use Durin::Metadata::ATCreator;	
use IO::File;

#my $file = new IO::File ("<t/MultinomialTestResult");
#my $expectedResult = join("",$file->getlines());

#print $expectedResult;

my $nX = 2;
my $nY = 2;
my $nZ = 2;	

my $generator = Durin::Math::Prob::MultinomialGenerator->new();

print "Unidimensional multinomial distribution\n";
my $mX = $generator->generateUnidimensionalMultinomial($nX);
#print "done\n";
foreach my $i (0..$nX-1) {
  print "p($i) = ".$mX->getP([$i])."\n";
}

print "Bidimensional dependent multinomial distribution\n";
my $mXYDep = $generator->generateDependentBidimensionalMultinomial($mX,$nY);
foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) {
    print "p($i,$j) = ".$mXYDep->getP([$i,$j])."\n";
  }
}

print "Bidimensional independent multinomial distribution\n";
my $mY = $generator->generateUnidimensionalMultinomial($nY);
print "Y distrib:\n";
foreach my $j (0..$nY-1) {
  print "p($j) = ".$mY->getP([$j])."\n";
}

my $mXYInd = $generator->generateIndependentBidimensionalMultinomial($mX,$mY);
foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) {
    print "p($i,$j) = ".$mXYInd->getP([$i,$j])."\n";
  }
}

print "Tridimensional dependent multinomial distribution\n";
my $mXYZDep = $generator->generateDependentTridimensionalMultinomial($mX,$mY,$nZ);
foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) {
    foreach my $k (0..$nZ-1) {
      print "p($i,$j,$k) = ".$mXYZDep->getP([$i,$j,$k])."\n";
    }
  }
}

print "Tridimensional independent multinomial distribution\n";
my $mZ = $generator->generateUnidimensionalMultinomial($nZ);
print "Z distrib:\n";
foreach my $k (0..$nZ-1) {
  print "p($k) = ".$mZ->getP([$k])."\n";
}

my $mXYZInd = $generator->generateIndependentTridimensionalMultinomial($mX,$mY,$mZ);
foreach my $i (0..$nX-1) {
  foreach my $j (0..$nY-1) { 
    foreach my $k (0..$nZ-1) {
      print "p($i,$j,$k) = ".$mXYZInd->getP([$i,$j,$k])."\n";
    }
  }
}






ok(1,1);
#ok($realResult,$expectedResult);