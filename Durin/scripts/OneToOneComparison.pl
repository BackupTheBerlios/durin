#!/usr/bin/perl -w

use strict;
use warnings;
use IO::File;
use Durin::Utilities::StringUtilities;
use Statistics::Distributions;

my $inputFileName = $ARGV[0];
my $percentage = 5;
if ($#ARGV == 1) {
  $percentage = $ARGV[1];
}
my $inFile = new IO::File();
$inFile->open("<$inputFileName");
my $line = $inFile->getline();
$line = Durin::Utilities::StringUtilities::removeEnter($line);
my $results = {};
while (!$inFile->eof())
  {
    my ($nameClassifier,$resultsClassifierCSV) = split(/:/,$line);
    my @resultsClassifier = split(/,/,$resultsClassifierCSV);
    $results->{$nameClassifier} = \@resultsClassifier;
    #print (join(",",@array),"\n");
    $line = $inFile->getline();
    $line = Durin::Utilities::StringUtilities::removeEnter($line);
  }
#my @array = split(/:/,$line);
#if ($#array>1)
#  {
#    print (join(",",@array),"\n");
#  }
$inFile->close();

foreach my $classifier1 (keys %$results) {
  foreach my $classifier2 (keys %$results) {
    significanceTest($results,$classifier1,$classifier2,$percentage);
   # my $AMB = 0;
#    my $BMA = 0; 
#    my $Equal = 0;
#    for (my $i = 0; $i < scalar(@{$results->{$classifier1}}) ; $i++) {
#      my $val1 = $results->{$classifier1}->[$i];
#      my $val2 = $results->{$classifier2}->[$i];
#      if ($val1 > $val2) {
#	$BMA++;
#      } elsif($val1 < $val2) {
#	$AMB++;
#      } else {
#	$Equal++;
#      }
#    }
#    print "$classifier1 better than $classifier2 $AMB times\n";
#    print "$classifier2 better than $classifier1 $BMA times\n";
#    print "$classifier1 equal $classifier2 $Equal times\n";
  }
}

sub significanceTest {
  my ($results,$classifier1,$classifier2,$percentage) = @_;
  
  my $results1 = $results->{$classifier1};
  my $results2 = $results->{$classifier2};
  my $ERdifference = [];
  my $i = 0 ;
  foreach my $result1 (@$results1) {
    push @$ERdifference,($result1 - $results2->[$i]);
    $i++;
  }
  
  my $UValue = calculateUValue($ERdifference);
  my $n = scalar(@$ERdifference);
  my $U99 = Statistics::Distributions::tdistr($n-1,$percentage/100);
  #print "n:$n  U: $UValue c:$U99\n";
  if ($UValue>$U99) {
    print "$classifier2 sign. better than $classifier1 at $percentage%\n";
  } else {
    #print "No sign. difference\n";
  }
  #print join(",",@$ERdifference)."\n\n";
}

sub calculateUValue {
  my ($ERdifference) = @_;

  my $n = scalar(@$ERdifference);
  my $sum = 0;
  foreach my $x (@$ERdifference) {
    $sum += $x;
  }
  my $xav = $sum / $n;
  my $sn2 = 0;
  foreach my $x (@$ERdifference) {
    $sn2 += ($x - $xav)*($x - $xav);
  }
  #print join(",",@$ERdifference)."\n\n";
  #print "sn2:$sn2\n";

  if ($sn2==0) {
    return 0;
  }
  return (sqrt($n)*$xav)/(sqrt($sn2/($n-1)));
}



#End
