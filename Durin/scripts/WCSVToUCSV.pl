#!/usr/local/bin/perl -w

# Converts a WCSV into a UCSV

use strict;
use IO::File;
use Durin::Utilities::StringUtilities;

my $inputFileName = $ARGV[0];
my $outputFileName = $ARGV[1];

my $inFile = new IO::File;
$inFile->open("<$inputFileName") or die "Unable to open $inputFileName\n";
my $outFile = new IO::File;
$outFile->open(">$outputFileName") or die "Unable to open $outputFileName\n";

# read the headers (the field names)
my $line = $inFile->getline();
$line = Durin::Utilities::StringUtilities::removeCtrlMEnter($line);
while (!$inFile->eof())
  {
    print $outFile ($line."\n");
    $line = $inFile->getline();
    $line = Durin::Utilities::StringUtilities::removeCtrlMEnter($line);
  }
my @array = split(/,/,$line);
if ($#array>1)
  {
    print $outFile ($line."\n");
  }

$inFile->close();
$outFile->close();
