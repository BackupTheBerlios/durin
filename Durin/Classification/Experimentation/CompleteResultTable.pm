# Contains the table of results that summarizes and experiment. That means it has:
# 
# Dataset x Method x Percentage x RunNumber
#

package Durin::Classification::Experimentation::CompleteResultTable;

#use base Durin::Components::Data;
use base Durin::Classification::Experimentation::ResultTable;

use strict;
use warnings;

use PDL;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    $self->{RESULTLIST} = [];
    $self->{RESULTSCLASSIFIEDS} = {};
    $self->{PROPORTIONS} = {};
    $self->{MODELS} = {};
    $self->{DATASETS} = {}; 
    $self->{MODELSLIST} = [];
    $self->{DATASETSLIST} = [];
    $self->{PDLTABLE} = undef;
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    die "Durin::Classification::Experimentation::ResultTable::clone not implemented\n";
  }


sub addResult
  {
    my ($self,$dataset,$idNum,$foldNum,$trainProportion,$modelName,$modelApplication) = @_;
    
    if (!(exists $self->{PROPORTIONS}->{$trainProportion}))
      {
	$self->{PROPORTIONS}->{$trainProportion} = undef;
      }
    if (!(exists $self->{DATASETS}->{$dataset}))
      {
	#my $datasetIndex = scalar(@{$self->getDatasets()}) ;
	#print "Inserting Dataset: $dataset. Number = $datasetIndex\n";
	$self->{DATASETS}->{$dataset} = scalar(@{$self->getDatasets()});
	push @{$self->{DATASETSLIST}},$dataset;
      }
    if (!(exists $self->{MODELS}->{$modelName}))
      {
	$self->{MODELS}->{$modelName} = scalar(@{$self->getModels()});
	push @{$self->{MODELSLIST}},$modelName;
      }
    
    # print $model->getName(),"\n";
    push @{$self->{RESULTLIST}},([$dataset,$modelName,$trainProportion,$idNum,$foldNum,$modelApplication]);
    $self->{RESULTSCLASSIFIEDS}->{$dataset}->{$modelName}->{$trainProportion}->{$idNum}->{$foldNum} = $modelApplication;
    #print "Added Model:$modelName, Dataset:$dataset\n";
  }

sub getResults
  {
    my ($self) = @_;
    
    return $self->{RESULTLIST};
  }


# Returns any proportion that has been tried over any dataset. Possibly not all experiments have the same set of proportions.
sub getProportions
  {
    my ($self) = @_;
    
    my @list = (sort (keys %{$self->{PROPORTIONS}}));
    return \@list;
  }

sub getModels
  {
    my ($self) = @_;
    
    return $self->{MODELSLIST};
  }

sub getDatasets
  {
    my ($self) = @_;

    return $self->{DATASETSLIST};
  }

# Returns a list of ModelApplications
sub getResultsByDatasetModelAndProportion {
  my ($self,$dataset,$model,$proportion) = @_;
  
  my $modelApplicationList = [];
  my $vect = $self->{RESULTSCLASSIFIEDS}->{$dataset}->{$model}->{$proportion};
  #print join(",",keys %$vect)."\n";
  
  my @IdNums = (keys %$vect);
  #print "It has been run ".($#IdNums+1)." times\n";
  #print "Number of runs: ",$#IdNums + 1,"\n";
  foreach my $idNum (@IdNums)
    {
      # Here we treat CV results.
      my $run = $vect->{$idNum};
      #print join(",",keys %$run)."\n";
      
      my @numFolds = (keys %$run);
      #print "Run $idNum has ".($#numFolds+1)." folds \n";
      #print "Number of folds = ",$#numFolds + 1,"\n";
      foreach my $foldNum (@numFolds)
	{
	  push @$modelApplicationList,$run->{$foldNum};
	}
    }
  return $modelApplicationList;
}

sub compressRuns {
  my ($self) = @_;

  my $proportionList = $self->getProportions();
  foreach my $proportion (@$proportionList) {
    print "Processing proportion: $proportion\n";
    $self->compressRunsByProportion($proportion);
  }
}

# Calculate averages and std. deviations over the different runs.

sub compressRunsByProportion 
  {
    my ($self,$proportion) = @_;
    
    my $models = $self->getModels();
    my $datasets = $self->getDatasets(); 
    my $dim1 = scalar(@$models);
    my $dim2 = scalar(@$datasets);
    #print "Models: $dim1, Datasets: $dim2\n";

    $self->{$proportion}->{PDLERAVERAGETABLE} = zeroes $dim1,$dim2;
    $self->{$proportion}->{PDLERSTDEVTABLE} = zeroes $dim1,$dim2;
    $self->{$proportion}->{PDLLOGPAVERAGETABLE} = zeroes $dim1,$dim2;
    $self->{$proportion}->{PDLLOGPSTDEVTABLE} = zeroes $dim1,$dim2;
    $self->{$proportion}->{PDLAUCAVERAGETABLE} = zeroes $dim1,$dim2;
    $self->{$proportion}->{PDLAUCSTDEVTABLE} = zeroes $dim1,$dim2;
    
    my $modelIndex;
    foreach my $model (@$models)
      {
	$modelIndex = $self->{MODELS}->{$model};
	my $datasetIndex;
	foreach my $dataset (@$datasets)
	  {
	    $datasetIndex = $self->{DATASETS}->{$dataset};
	    print "Model: $model Dataset: $dataset\n";
	    my $vect = $self->{RESULTSCLASSIFIEDS}->{$dataset}->{$model}->{$proportion};
	    #print join(",",keys %$vect)."\n";
	    
	    my @IdNums = (keys %$vect);
	    my ($ERAverage,$ERRMS,$ERMedian,$ERMin,$ERMax);
	    my ($LogPAverage,$LogPRMS,$LogPMedian,$LogPMin,$LogPMax);
	    my ($AUCAverage,$AUCRMS,$AUCMedian,$AUCMin,$AUCMax);
	    	    
	    print "It has been run ".($#IdNums+1)." times\n";
	    if ($#IdNums != -1)
	      {
		my $ERList = zeroes $#IdNums+1;
		my $LogPList = zeroes $#IdNums+1;
		my $AUCList = zeroes $#IdNums+1;
		my $runIndex = 0;
		#print "Number of runs: ",$#IdNums + 1,"\n";
		foreach my $idNum (@IdNums)
		  {
		    # Here we treat CV results.
		    my $run = $vect->{$idNum};
		    #print join(",",keys %$run)."\n";
		    
		    my @numFolds = (keys %$run);
		    print "Run $idNum has ".($#numFolds+1)." folds \n";
		    my $runERList =  zeroes $#numFolds+1;
		    my $runLogPList = zeroes $#numFolds+1;
		    my $runAUCList = zeroes $#numFolds+1;
		    my $foldNumIndex = 0;
		    #print "Number of folds = ",$#numFolds + 1,"\n";
		    foreach my $foldNum (@numFolds)
		      {
			#print "Position: $foldNumIndex\n";
			#print "ER:".$run->{$foldNum}->getErrorRate()."\n";
			set $runERList,$foldNumIndex,$run->{$foldNum}->getErrorRate()*1;
			set $runLogPList,$foldNumIndex,$run->{$foldNum}->getLogP();
			set $runAUCList,$foldNumIndex,$run->{$foldNum}->getAUC();
			$foldNumIndex++;
		      }
		    ($ERAverage,$ERRMS,$ERMedian,$ERMin,$ERMax) = stats($runERList);
		    ($LogPAverage,$LogPRMS,$LogPMedian,$LogPMin,$LogPMax) = stats($runLogPList);
		    ($AUCAverage,$AUCRMS,$AUCMedian,$AUCMin,$AUCMax) = stats($runAUCList);
		    
		    
		    set $ERList,$runIndex,$ERAverage;
		    set $LogPList,$runIndex,$LogPAverage;
		    set $AUCList,$runIndex,$AUCAverage;
		    $runIndex++;
		  }
		if ($#IdNums != 0) {
		  ($ERAverage,$ERRMS,$ERMedian,$ERMin,$ERMax) = stats($ERList);
		  ($LogPAverage,$LogPRMS,$LogPMedian,$LogPMin,$LogPMax) = stats($LogPList);
		  ($AUCAverage,$AUCRMS,$AUCMedian,$AUCMin,$AUCMax) = stats($AUCList);
		}
	      } else {
		($ERAverage,$ERRMS,$ERMedian,$ERMin,$ERMax) = (-1,0,-1,-1,-1);
		($LogPAverage,$LogPRMS,$LogPMedian,$LogPMin,$LogPMax) = (-1,0,-1,-1,-1);
	 	($AUCAverage,$AUCRMS,$AUCMedian,$AUCMin,$AUCMax) = (-1,0,-1,-1,-1);
	      }
	    #print "Average: $ERAverage\n";
	    set $self->{$proportion}->{PDLERAVERAGETABLE},$modelIndex,$datasetIndex,$ERAverage;
	    set $self->{$proportion}->{PDLERSTDEVTABLE},$modelIndex,$datasetIndex,sqrt($ERRMS);
	    set $self->{$proportion}->{PDLLOGPAVERAGETABLE},$modelIndex,$datasetIndex,$LogPAverage;
	    set $self->{$proportion}->{PDLLOGPSTDEVTABLE},$modelIndex,$datasetIndex,sqrt($LogPRMS);
	    set $self->{$proportion}->{PDLAUCAVERAGETABLE},$modelIndex,$datasetIndex,$AUCAverage;
	    set $self->{$proportion}->{PDLAUCSTDEVTABLE},$modelIndex,$datasetIndex,sqrt($AUCRMS);
	    #$datasetIndex++;
	  }
	#$modelIndex++;
      }
    #my $model = $models->[4];
    #my $piddleA = $self->getAvERDatasets($model);
    #print "$model ER: $piddleA\n"
  }

sub getMinimumERForDatasetAndProportion {
  my ($self,$dataset,$proportion) = @_;

  my $pdl = $self->getAvERModels($dataset,$proportion);
  my $nelem = $pdl->nelem();

  #  print "num elems:$nelem\n";
  my $i = 0;
  my $min = exp(10000);
  while ($i < $nelem)
    {
      my $val = $pdl->at($i);
      #print "Val:$val\n";
      if ($val != -1) {
	if ($val < $min)
	  {
	    $min = $val;
	  }
      }
      $i++;
    }
  return $min;
}

sub getMinimumLogPForDatasetAndProportion {
  my ($self,$dataset,$proportion) = @_;
  
  my $pdl = $self->getAvLogPModels($dataset,$proportion);
  my $nelem = $pdl->nelem();

  #print "num elems:$nelem\n";
  my $i = 0;
  my $min = exp(10000);
  while ($i < $nelem)
    {
      my $val = $pdl->at($i);
      #print "Val:$val\n";
      if ($val != -1) {
	if ($val < $min)
	  {
	    $min = $val;
	  }
      }
      $i++;
    }
  return $min;
}

sub getMinimumAUCForDatasetAndProportion {
  my ($self,$dataset,$proportion) = @_;
  
  my $pdl = $self->getAvAUCModels($dataset,$proportion);
  my $nelem = $pdl->nelem();

  #print "num elems:$nelem\n";
  my $i = 0;
  my $min = exp(10000);
  while ($i < $nelem)
    {
      my $val = $pdl->at($i);
      #print "Val:$val\n";
      if ($val != -1) {
	if ($val < $min)
	  {
	    $min = $val;
	  }
      }
      $i++;
    }
  return $min;
}

sub HasModelMinimumERForDatasetAndProportion {
  my ($self,$model,$dataset,$proportion) = @_;

  my $min = $self->getMinimumERForDatasetAndProportion($dataset,$proportion);
  return ($min == $self->getAvER($model,$dataset,$proportion));
}

sub HasModelMinimumLogPForDatasetAndProportion {
  my ($self,$model,$dataset,$proportion) = @_;
  
  my $min = $self->getMinimumLogPForDatasetAndProportion($dataset,$proportion);
  return ($min == $self->getAvLogP($model,$dataset,$proportion));
}
  
sub HasModelMinimumAUCForDatasetAndProportion {
  my ($self,$model,$dataset,$proportion) = @_;
  
  my $min = $self->getMinimumAUCForDatasetAndProportion($dataset,$proportion);
  return ($min == $self->getAvAUC($model,$dataset,$proportion));
}
  
sub getAvER {
  my ($self,$model,$dataset,$proportion) = @_;
  my $modelIndex = $self->{MODELS}->{$model};
  my $datasetIndex = $self->{DATASETS}->{$dataset};
  
  return $self->{$proportion}->{PDLERAVERAGETABLE}->at($modelIndex,$datasetIndex);
}

sub getStDevER {
  my ($self,$model,$dataset,$proportion) = @_;
  my $modelIndex = $self->{MODELS}->{$model};
  my $datasetIndex = $self->{DATASETS}->{$dataset};
  
  return $self->{$proportion}->{PDLERSTDEVTABLE}->at($modelIndex,$datasetIndex);
}

sub getAvLogP {
  my ($self,$model,$dataset,$proportion) = @_;
  my $modelIndex = $self->{MODELS}->{$model};
  my $datasetIndex = $self->{DATASETS}->{$dataset};
  
  return $self->{$proportion}->{PDLLOGPAVERAGETABLE}->at($modelIndex,$datasetIndex);
}

sub getStDevLogP {
  my ($self,$model,$dataset,$proportion) = @_;
  my $modelIndex = $self->{MODELS}->{$model};
  my $datasetIndex = $self->{DATASETS}->{$dataset};
  
  return $self->{$proportion}->{PDLLOGPSTDEVTABLE}->at($modelIndex,$datasetIndex);
}
sub getAvAUC {
  my ($self,$model,$dataset,$proportion) = @_;
  my $modelIndex = $self->{MODELS}->{$model};
  my $datasetIndex = $self->{DATASETS}->{$dataset};
  
  return $self->{$proportion}->{PDLAUCAVERAGETABLE}->at($modelIndex,$datasetIndex);
}

sub getStDevAUC {
  my ($self,$model,$dataset,$proportion) = @_;
  my $modelIndex = $self->{MODELS}->{$model};
  my $datasetIndex = $self->{DATASETS}->{$dataset};
  
  return $self->{$proportion}->{PDLAUCSTDEVTABLE}->at($modelIndex,$datasetIndex);
}

sub getAvERModels
  {
    my ($self,$dataset,$proportion)  = @_;
    
    my $datasetIndex = $self->{DATASETS}->{$dataset};
    
    my $pdl = $self->{$proportion}->{PDLERAVERAGETABLE}->slice(":,($datasetIndex)");
   
    return $pdl;
  }

sub getAvERDatasets
  {
    my ($self,$model,$proportion)  = @_;
    
    my $modelIndex = $self->{MODELS}->{$model};
    
    my $pdl = $self->{$proportion}->{PDLERAVERAGETABLE}->slice("($modelIndex),:");
   
    return $pdl;
  }

sub getAvLogPModels
  {
    my ($self,$dataset,$proportion)  = @_;
    
    my $datasetIndex = $self->{DATASETS}->{$dataset};
    
    my $pdl = $self->{$proportion}->{PDLLOGPAVERAGETABLE}->slice(":,($datasetIndex)");
   
    return $pdl;
  }

sub getAvLogPDatasets
  {
    my ($self,$model,$proportion)  = @_;
    
    my $modelIndex = $self->{MODELS}->{$model};
    
    my $pdl = $self->{$proportion}->{PDLLOGPAVERAGETABLE}->slice("($modelIndex),:");
   
    return $pdl;
  }

sub getAvAUCModels
  {
    my ($self,$dataset,$proportion)  = @_;
    
    my $datasetIndex = $self->{DATASETS}->{$dataset};
    
    my $pdl = $self->{$proportion}->{PDLAUCAVERAGETABLE}->slice(":,($datasetIndex)");
   
    return $pdl;
  }

sub getAvAUCDatasets
  {
    my ($self,$model,$proportion)  = @_;
    
    my $modelIndex = $self->{MODELS}->{$model};
    
    my $pdl = $self->{$proportion}->{PDLAUCAVERAGETABLE}->slice("($modelIndex),:");
   
    return $pdl;
  }

1;
