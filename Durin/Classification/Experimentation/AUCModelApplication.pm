# Contains the results of an application of a classification model to a dataset

package Durin::Classification::Experimentation::AUCModelApplication;

use Durin::Classification::Experimentation::ModelApplication;
use Durin::Utilities::MathUtilities;
@ISA = (Durin::Classification::Experimentation::ModelApplication);

use strict;

sub new_delta 
{     
    my ($class,$self) = @_;
    
    $self->{INSTANCE_LIST} = [];
}

sub clone_delta
{  
  # my ($class,$self,$source) = @_;
  
  die "Durin::Classification::Experimentation::AUCModelApplication::clone not implemented\n";
}

#sub initializeClassValues {
#  my ($self,$classValues) = @_;
#  
#  $self->{CLASS_VALUES} = $classValues;
#}

sub addInstance
  {
    my ($self,$realClass,$distrib,$class) = @_;
    
    push @{$self->{INSTANCE_LIST}},[$realClass,$distrib,$class];
  }

sub write {
  my ($self,$outFileName) = @_;

  my $file = new IO::File;
  $file->open(">$outFileName") or die "Unable to open input file: $outFileName\n";
  my $classValues = $self->{CLASS_VALUES};
  foreach my $instance (@{$self->{INSTANCE_LIST}})
    {
      my ($realClass,$probList,$predictedClass) = @$instance;
      print $file "$realClass,".join(",",@$probList).",$predictedClass\n";
    }
  $file->close();
}

sub computeAUCClassPair {
  my ($self, $possitiveClass, $negativeClass) = @_;
 
  my $possitiveClassPosition = $possitiveClass+1;
  my @pairList = grep {(($_->[0] == $possitiveClass) || ($_->[0] == $negativeClass))} @{$self->{INSTANCE_LIST}};
  my @sortedList = sort {$b->[1]->[$possitiveClass] <=> $a->[1]->[$possitiveClass]} @pairList;
  foreach my $inst (@pairList)
    {
      print $inst->[0].",".join(",",@{$inst->[1]})."\n";
    }
  print "And sorted\n";
  foreach my $inst (@sortedList)
    {
       print $inst->[0].",".join(",",@{$inst->[1]})."\n";
    }
  
  my $fp = 0;
  my $tp = 0;
  my $fpprev = 0;
  my $tpprev = 0;
  my $a = 0;
  my $fprev = -100000000000;
  foreach my $instance (@sortedList) {
    my $f_i = $instance->[1]->[$possitiveClassPosition];
    if ($f_i != $fprev) {
      $a = $a + $self->trap_area($fp,$fpprev,$tp,$tpprev); 
      $fprev = $f_i;
      
      $fpprev = $fp;
      $tpprev = $tp;
    }
    if ($instance->[0] == $possitiveClass) {
      $tp++;
    } else {
      $fp++;
    }
  }
  $a = $a + $self->trap_area($fp,$fpprev,$tp,$tpprev);
  $a = $a/($tp*$fp);
  return $a;
}

sub trap_area {
  my ($self,$x1,$x2,$y1,$y2) = @_;
  
  my $base = abs($x1-$x2);
  my $height = ($y1+$y2)/2;
  return ($base * $height);
}

sub computeAUC {
  my ($self) = @_;

  my $AUC = $self->computeAUCClassPair(0,1);
  
  return $AUC;
}
