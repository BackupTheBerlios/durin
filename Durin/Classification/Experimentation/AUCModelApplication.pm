# Contains the results of an application of a classification model to a dataset

package Durin::Classification::Experimentation::AUCModelApplication;

use Durin::Classification::Experimentation::ModelApplication;
use Durin::Utilities::MathUtilities;
@ISA = (Durin::Classification::Experimentation::ModelApplication);
use Class::MethodMaker get_set => [-java => qw/ AUC LogP ErrorRate NumClasses Summarized/];

use strict;
use warnings;

sub new_delta {     
  my ($class,$self) = @_;
  
  $self->{INSTANCE_LIST} = [];
  $self->{INSTANCE_PROBABILITY_LIST} = [];
  $self->setSummarized(0);
}

sub clone_delta
{  
  # my ($class,$self,$source) = @_;
  
  die "Durin::Classification::Experimentation::AUCModelApplication::clone not implemented\n";
}

sub freeInstances {
  my ($self) = @_;
  $self->{INSTANCE_LIST} = [];
  $self->{INSTANCE_PROBABILITY_LIST} = [];
}

sub addInstance
  {
    my ($self,$realClass,$distrib,$class) = @_;
    
    #print "Adding $realClass,".join(",",@$distrib).",$class\n";
    push @{$self->{INSTANCE_LIST}},[$realClass,$distrib,$class];
  }

sub addInstanceBayes
  {
    my ($self,$realClass,$realProbDistrib,$sum,$distrib,$class) = @_;
    
    $self->addInstance($realClass,$distrib,$class);
    push @{$self->{INSTANCE_PROBABILITY_LIST}},[$realProbDistrib,$sum];
  }

sub write {
  my ($self,$outFileName) = @_;

  my $file = new IO::File;
  $file->open(">$outFileName") or die "Unable to open input file: $outFileName\n";
  foreach my $instance (@{$self->{INSTANCE_LIST}})
    {
      my ($realClass,$probList,$predictedClass) = @$instance;
      print $file "$realClass,".join(",",@$probList).",$predictedClass\n";
    }
  $file->close();
}


sub computeAUC {
  my ($self) = @_;

  my $AUC = 0;
 
  my $numClasses = $self->getNumClasses();
  #print "NumClasses: $numClasses\n";
  for (my $i = 0; $i < $numClasses ; $i++) {
    for (my $j = 0; $j < $numClasses ; $j++) {
      if ($i > $j) {
	#print "Computing AUC($i, $j)\n";
	my $thisAUC = $self->computeAUCClassPair($i,$j);
	#print "AUC($i, $j) = $thisAUC\n";
	$AUC += $thisAUC;
      } 
    }
  }
  
  $AUC = ($AUC * 2) /($numClasses*($numClasses-1));
    
  return $AUC;
}

sub computeAUCClassPair {
  my ($self, $possitiveClass, $negativeClass) = @_;
 
  #print "Possitive = $possitiveClass\n";
  #foreach my $inst (@{$self->{INSTANCE_LIST}})
  #   {
  #     print $inst->[0].",".join(",",@{$inst->[1]})."\n";
  #   }
  my @pairList = grep {(($_->[0] == $possitiveClass) || ($_->[0] == $negativeClass))} @{$self->{INSTANCE_LIST}};
  # foreach my $inst (@pairList)
  #   {
  #     print $inst->[0].",".join(",",@{$inst->[1]})."\n";
  #   }
  my @sortedList = sort {$b->[1]->[$possitiveClass] <=> $a->[1]->[$possitiveClass]} @pairList;
  #  foreach my $inst (@{$self->{INSTANCE_LIST}})
  #    {
  #      print $inst->[0].",".join(",",@{$inst->[1]})."\n";
  #    }
  #  print "And sorted\n";
  #  foreach my $inst (@sortedList)
  #    {
  #       print $inst->[0].",".join(",",@{$inst->[1]})."\n";
  #    }
  
  my $fp = 0;
  my $tp = 0;
  my $fpprev = 0;
  my $tpprev = 0;
  my $a = 0;
  my $fprev = -100000000000;
  foreach my $instance (@sortedList) {
    my $f_i = $instance->[1]->[$possitiveClass];
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
  if (($tp==0) || ($fp ==0)) {
    $a = 1;
  } else {
    $a = $a/($tp*$fp);
  }
  return $a;
}

sub trap_area {
  my ($self,$x1,$x2,$y1,$y2) = @_;
  
  my $base = abs($x1-$x2);
  my $height = ($y1+$y2)/2;
  return ($base * $height);
}

sub readFromFile {
  my ($self,$fileName) = @_;
  
  print "Reading model application from $fileName\n";
  my $file = IO::File->new;
  $file->open("<$fileName");
  my @lines = readline $file;
  my @line = ();
  foreach my $line (@lines) {
    @line = split(/,/,$line);
    my $realClass = $line[0];
    my $predictedClass = $line[(scalar @line) - 1];
    pop @line;
    shift @line;
    my @new_line = @line;
    $self->addInstance($realClass,\@new_line,$predictedClass);
  }
  $self->setNumClasses(scalar @line);
}

sub computeLogP {
  my ($self) = @_;
  
  my $LogP = 0;
  foreach my $inst ( @{$self->{INSTANCE_LIST}})
    {
      my $PClass = $inst->[1]->[$inst->[0]];
      if ($PClass <= 0)
	{
	  print "A probability evaluated to 0 or even less. Just another illogical prediction\n";
	  $LogP += 15000000; # Just something big
	}
      else
	{
	  $LogP -= Durin::Utilities::MathUtilities::log10($PClass);
	}
    }
  return $LogP;
}

sub computeErrorRate {
  my ($self) = @_;
  
  my $Errors = 0;
  my $Total = 0;
  foreach my $inst ( @{$self->{INSTANCE_LIST}})
    {
      $Total++;
      if ($inst->[2] != $inst->[0]) {
	$Errors++;
      }
    }
  return ($Errors/$Total);
}

sub summarize {
  my ($self) = @_;

  if (!$self->getSummarized()) {
    $self->setAUC($self->computeAUC());
    print "AUC:".$self->getAUC()."\n";
    $self->setLogP($self->computeLogP());
    print "LogP:".$self->getLogP()."\n";
    $self->setErrorRate($self->computeErrorRate()); 
    print "ER:".$self->getErrorRate()."\n";
    $self->setSummarized(1);
    $self->freeInstances();
  }
}

sub computeAUCBayes {
  my ($self) = @_;

  my $AUC = 0;
 
  my $numClasses = $self->getNumClasses();
  #print "NumClasses: $numClasses\n";
  for (my $i = 0; $i < $numClasses ; $i++) {
    for (my $j = 0; $j < $numClasses ; $j++) {
      if ($i > $j) {
	print "Computing Bayes AUC($i, $j)\n";
	my $thisAUC = $self->computeAUCClassPairBayes($i,$j);
	print "AUC($i, $j) = $thisAUC\n";
	$AUC += $thisAUC;
      }
    }
  }
  $AUC = ($AUC * 2) /($numClasses*($numClasses-1));
  return $AUC;
}

sub computeAUCClassPairBayes {
  my ($self, $possitiveClass, $negativeClass) = @_;
 
  my @fullList = ();
  for (my $i = 0 ; $i < scalar @{$self->{INSTANCE_LIST}} ; $i++) {
    my @elem = @{$self->{INSTANCE_LIST}->[$i]};
    #print "Elem contains: ".join(",",@elem)."\n";
    push @elem, @{$self->{INSTANCE_PROBABILITY_LIST}->[$i]};
    push @fullList, \@elem;
  }
  my @pairList = grep {(($_->[0] == $possitiveClass) || ($_->[0] == $negativeClass))} @fullList;
  #foreach my $inst (@pairList)
  #  {
  #    
  #    print $inst->[0].",(".join(",",@{$inst->[1]})."),".$inst->[2].",(".join(",",@{$inst->[3]})."),".$inst->[4]."\n";
  #  }
  my @sortedList = sort {$b->[1]->[$possitiveClass] <=> $a->[1]->[$possitiveClass]} @pairList;
  
  my $fp = 0;
  my $tp = 0;
  my $fpprev = 0;
  my $tpprev = 0;
  my $a = 0;
  my $fprev = -100000000000;
  foreach my $instance (@sortedList) {
    #my $f_i = $instance->[1]->[$possitiveClass];
    #if ($f_i != $fprev) {
    $a = $a + $self->trap_area($fp,$fpprev,$tp,$tpprev); 
    #$fprev = $f_i;
    
    $fpprev = $fp;
    $tpprev = $tp;
    #}
    #if ($instance->[0] == $possitiveClass) {
    my $pInstance = $instance->[4];
    $tp += $instance->[3]->[$possitiveClass]/$pInstance; # Add the probability of the instance instead of one
    #} else {
    $fp += $instance->[3]->[$negativeClass]/$pInstance; 
    #}
  }
  $a = $a + $self->trap_area($fp,$fpprev,$tp,$tpprev);
  if (($tp==0) || ($fp ==0)) {
    # We have to get into more detail here!!!!!!!
    $a = 1;
  } else {
    $a = $a/($tp*$fp);
  }
  return $a;
}

sub computeLogPBayes {
  my ($self) = @_;
  
  my $LogP = 0;
  my $i = 0;
  my $pInstance;
  foreach my $inst (@{$self->{INSTANCE_LIST}})
    {
      my $PClass = $inst->[1]->[$inst->[0]];
      if ($PClass <= 0)
	{
	  print "A probability evaluated to 0 or even less. Just another illogical prediction\n";
	  $LogP += 15000000; # Just something big
	}
      else
	{
	  $pInstance = $self->{INSTANCE_PROBABILITY_LIST}->[$i]->[1];
	  $LogP -= $pInstance * Durin::Utilities::MathUtilities::log10($PClass);
	}
      $i++;
    }
  return $LogP;
}

sub computeErrorRateBayes {
  my ($self) = @_;
  
  my $expectedError = 0;
  my $expectedErrorRate = 0;
  my $predictedClass;
  my $realCondProbabilityOfPredictedClass;
  my $i = 0;
  my $pInstance;
  foreach my $inst (@{$self->{INSTANCE_LIST}})
    {
      $pInstance = $self->{INSTANCE_PROBABILITY_LIST}->[$i]->[1];
      $predictedClass = $inst->[2];
      $realCondProbabilityOfPredictedClass = $self->{INSTANCE_PROBABILITY_LIST}->[$i]->[0]->[$predictedClass] / $pInstance;
      $expectedError = $pInstance * (1 - $realCondProbabilityOfPredictedClass);
      $i++;
      #print "Predicted: $predictedClass , Prob Instance: $pInstance Real Cond Prob Predicted Class: $realCondProbabilityOfPredictedClass  Error expected:$expectedError\n";
      $expectedErrorRate += $expectedError;
    }
  return $expectedErrorRate;
}

sub summarizeBayes {
  my ($self) = @_;

  if (!$self->getSummarized()) {
    $self->setAUC($self->computeAUCBayes());
    $self->setLogP($self->computeLogPBayes());
    $self->setErrorRate($self->computeErrorRateBayes());
    $self->setSummarized(1);
    $self->freeInstances();
  }
}
