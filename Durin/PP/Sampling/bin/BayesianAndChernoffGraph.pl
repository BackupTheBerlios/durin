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
my $n = 250;

plotReal($N,$n);

sub plotReal
  {
    my ($N,$n) = @_;
    
    my $color = 1;
    
    dev $device;
    pgpap(5,1);
    
    my $items = 50;
    my @accuracies = ();
    for (my $i = 0; $i < $items ; $i++)
    {
	push @accuracies,(0.1 * $i/$items);
    }
    env 0,0.1, 0,1, 0,-2;
    pglab("Accuracy","Confidence",""); 
    pgaxis("N", 0,0 , 0.1,0 , 0,0.1, 0.01 , 0,0.5,0,0,1,0);
    pgaxis("N", 0,0 , 0,1 , 0,1, 0.1 , 0,0.5,0,0,-1,0);
    
    #pgtext(0.02,0.6,"Bayesian");
    #pgtext(0.042,0.6,"Chernoff");
    hold();
    
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
    my @line_styles =();
    push @line_styles,$color;
    line($x,$ycer,{LINESTYLE=>$color++});  hold();
    push @line_styles,$color;
    line($x,$ycher,{LINESTYLE=>$color++});  hold();
    legend ["Bayesian","Chernoff"],0.08,0.15,{LineStyle =>\@line_styles};
  }
