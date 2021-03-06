#!/usr/bin/perl

# Plots the a graph that shows that our confidence
# function has a minimum at frequency 0.5

use strict;
 
use PDL;
use PDL::Graphics::PGPLOT;
use PGPLOT;
use Durin::PP::Sampling::SamplingBounds;

my $device = "/XSERVE";
if ($#ARGV == 0) {
  $device = $ARGV[0];
}

my $N = 100000;
my $n = 1000;
my @epsList = (0.02,0.025,0.033,0.05,0.1);
plotConfidenceCurves(\@epsList,$N,$n);

sub plotConfidenceCurves {
  my ($epsList,$N,$n) = @_;
  
  #pgopen("/home/cerquide/My_Writings/Unix-Documents/tesis/figures/PP/EmpBayesProper.ps/VCPS"); 
  #pgopen("/XSERVE");
  dev $device;
  pgslw(1);
  pgpap(5,1); 
  env 0,1, 0.2,1, 0,-2;
  pglab("Frequency","Confidence","Confidence curves"); 
  pgaxis("N", 0,0.2 , 1,0.2 , 0,1, 0.1 , 0,0.5,0,0,1,0);
  pgaxis("N", 0,0.2 , 0,1 , 0.2,1, 0.1 , 0,0.5,0,0,-1,0);
  hold();
  my $line_style = 1;
  my @line_styles = ();
  foreach my $eps (@$epsList) {
    plotConfidenceCurveHypergeom($eps,$N,$n,$line_style);
    push @line_styles,$line_style; 
    $line_style++;
    plotConfidenceCurve($eps,$N,$n,$line_style);
    push @line_styles,$line_style; 
    $line_style++;
  }
  my @legends = @$epsList;
  my @styles = @line_styles;
  legend \@legends, 0.8,0.32 , {LineStyle => \@styles, Colour => 1, LineWidth => 10 };

}

sub plotConfidenceCurve {
  my ($eps,$N,$n,$color) = @_;
  
  my $i = 0;
  my $max = 20;
  my $x = zeroes $max+1;
  my $y = zeroes $max+1;
  my $r;
  while ($i <= $max) {
    my $freq = $i/$max;
    $r = int($freq*$n);
    set $x,$i,$freq;
    set $y,$i, Durin::PP::Sampling::SamplingBounds::CerquidesAddConfidence($N,$n,$r,$eps);
    $i++;
  }
  line($x,$y,{LINESTYLE=>$color});  hold();
}

sub plotConfidenceCurveHypergeom {
  my ($eps,$N,$n,$color) = @_;
  
  my $i = 0;
  my $max = 20;
  my $x = zeroes $max+1;
  my $y = zeroes $max+1;
  my $R;
  while ($i <= $max) {
    my $freq = $i/$max;
    $R = int($freq*$N);
    set $x,$i,$freq;
    set $y,$i, Durin::PP::Sampling::SamplingBounds::HypergeometricAddConfidence($N,$R,$n,$eps);
    $i++;
  }
  line($x,$y,{LINESTYLE=>$color});  hold();
}





