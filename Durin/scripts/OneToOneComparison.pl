#!/usr/bin/perl -w

use strict;
use warnings;
use IO::File;
use Durin::Utilities::StringUtilities;

my $inputFileName = $ARGV[0];
my $classifier1 =  $ARGV[1];
my $classifier2 =  $ARGV[2];
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
    my $AMB = 0;
    my $BMA = 0; 
    my $Equal = 0;
    for (my $i = 0; $i < scalar(@{$results->{$classifier1}}) ; $i++) {
      my $val1 = $results->{$classifier1}->[$i];
      my $val2 = $results->{$classifier2}->[$i];
      if ($val1 > $val2) {
	$BMA++;
      } elsif($val1 < $val2) {
	$AMB++;
      } else {
	$Equal++;
      }
    }
    print "$classifier1 better than $classifier2 $AMB times\n";
    print "$classifier2 better than $classifier1 $BMA times\n";
    print "$classifier1 equal $classifier2 $Equal times\n";
  }
}

#End
