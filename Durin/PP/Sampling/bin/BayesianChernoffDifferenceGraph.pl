#!/usr/bin/perl

use strict;
 
use IO::File;
use Durin::Utilities::StringUtilities;
use POSIX;
use PDL;
use PDL::Graphics::PGPLOT;
use PGPLOT;
use Durin::PP::Sampling::SamplingBounds;

my $device = "/XSERVE";
if ($#ARGV == 0) {
  $device = $ARGV[0];
}

my $N = 10000;

my $samplingSizes = [50,100,250,1000];
my @accuracies = plotDifferenceInit();
my @line_styles =();
my $style = 1;
foreach my $n (@$samplingSizes) {
  plotDifference($N,$n,\@accuracies,$style);
  push @line_styles,$style;
  $style++;
}
my @styles = reverse @line_styles;
my @sizes = reverse @$samplingSizes;
legend \@sizes,0.08,0.17,{LineStyle =>\@styles};

sub plotDifferenceInit {
  
  dev $device;
  pgslw(1);
  pgpap(5,1);
  
  my $items = 100;
  my @accuracies = ();
  for (my $i = 0; $i < $items ; $i++)
    {
      push @accuracies,(0.1 * $i/$items);
    }
  env 0,0.1, 0,0.8, 0,-2;
  pglab("Accuracy","Confidence","Bayesian confidence - Chernoff confidence"); 
  pgaxis("N", 0,0 , 0.1,0 , 0,0.1, 0.01 , 0,0.5,0,0,1,0);
  pgaxis("N", 0,0 , 0,0.8 , 0,0.8, 0.1 , 0,0.5,0,0,-1,0);
  
  hold();
  return @accuracies;
}

sub plotDifference {
  my ($N,$n,$accuracies,$style) = @_;
    
  my @accuracies = @$accuracies;
  
  my $yreal = zeroes scalar(@accuracies);
  my $ycer = zeroes scalar(@accuracies); 
  my $ycher = zeroes scalar(@accuracies);	
  my $x = zeroes scalar(@accuracies);
  my $i = 0;
  foreach my $eps (@accuracies)
    {
      set $x, $i, $eps;
      set $ycher, $i, Durin::PP::Sampling::SamplingBounds::ChernoffAddConfidence($n,$eps);
      set $ycer, $i, Durin::PP::Sampling::SamplingBounds::CerquidesAddConfidence($N,$n,int($n * 0.5),$eps);
      $i++;
    }	
  my $diff = $ycer-$ycher;
 
  line($x,$diff,{LINESTYLE=>$style});  hold();
}
