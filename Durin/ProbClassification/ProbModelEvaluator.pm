# Receives a table and a list of models. Evaluates the conditional likelihood of each model given the data in the table.

package Durin::ProbClassification::ProbModelEvaluator;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
  my ($self) = @_;
  
  my $Input = $self->getInput();
  my $table = $Input->{TABLE};
  my @modelList = @{$Input->{MODELLIST}};
  my $class_attno = $table->getMetadata()->getSchema()->getClassPos();
  #my %weights;
  my %logWeights;
  my $model;
  #  my ($sum,$previousSum);
  # $previousSum = 0;
  foreach $model (@modelList)
    {
      #      $weights{$model} = 1.0;
      #      $previousSum += 1.0;
      $logWeights{$model} = 0.0;
    }
  
  $table->open();
  $table->applyFunction(sub 
			{
			  my ($row) = @_;
			  
			  my $RealClass = $row->[$class_attno];
			  #$sum = 0;
			  foreach $model (@modelList)
			    {
			      my ($distrib,$class) = @{$model->predict($row)};
			      #$weights{$model} = ($weights{$model} * $distrib->{$class})/$previousSum;
			      $logWeights{$model} += log($distrib->{$RealClass});
			     
			      #$sum += $weights{$model};
			      # print $weights{$model},",";
			    }
			  #$previousSum = $sum;
			  #print "\n";
			}
		       );
  $table->close();
  my $max = $logWeights{$modelList[0]};
  foreach $model (@modelList)
    {
      if ($logWeights{$model} >= $max)
	{
	  $max = $logWeights{$model};
	}
      #print "LogWeight: ",$logWeights{$model},"\n";
    }
  #print "The maximum is: $max\n";
  #$sum = 0.0;
  my %newWeights;
  my $newSum = 0;
  foreach $model (@modelList)
    {
      #print "$logWeights{$model}\n";
      #print "LogWeight: ",$logWeights{$model},"\n";
      $logWeights{$model} = $logWeights{$model} - $max;
      $newWeights{$model} = exp ($logWeights{$model});
      #print "RealWeight: ",$newWeights{$model},"\n";
      $newSum += $newWeights{$model};
      #$sum += $weights{$model};
    }
  foreach $model (@modelList)
    {
      #$weights{$model} = $weights{$model}/$sum;
      $newWeights{$model} = $newWeights{$model}/$newSum;
      #print "Old = $weights{$model} New = $newWeights{$model},";
    }
  #print "\n";
  $self->setOutput(\%newWeights);
}

1;
