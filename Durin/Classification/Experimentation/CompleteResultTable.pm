# Contains the table of results that summarizes and experiment. That means it has:
# 
# Dataset x Method x Percentage x RunNumber
#

package Durin::Classification::Experimentation::CompleteResultTable;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

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
    
#    if (!(exists $self->{PROPORTIONS}->{$trainProportion}))
#      {
#	$self->{PROPORTIONS}->{$trainProportion} = undef;
#      }
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
    
    #my @list = (keys %{$self->{MODELS}});
    #return \@list;
    return $self->{MODELSLIST};
  }

sub getDatasets
  {
    my ($self) = @_;

    #my @list = (keys %{$self->{DATASETS}});
    #return \@list;
    return $self->{DATASETSLIST};
  }

# Calculate averages and std. deviations over the different runs.

sub compressRuns 
  {
    my ($self,$trainProportion) = @_;
    
    my $models = $self->getModels();
    my $datasets = $self->getDatasets(); 
    my $dim1 = scalar(@$models);
    my $dim2 = scalar(@$datasets);
    #print "Models: $dim1, Datasets: $dim2\n";

    $self->{PDLERAVERAGETABLE} = zeroes $dim1,$dim2;
    $self->{PDLERSTDEVTABLE} = zeroes $dim1,$dim2;
    $self->{PDLLOGPAVERAGETABLE} = zeroes $dim1,$dim2;
    $self->{PDLLOGPSTDEVTABLE} = zeroes $dim1,$dim2;
    
    my $modelIndex;
    foreach my $model (@$models)
      {
	$modelIndex = $self->{MODELS}->{$model};
	my $datasetIndex;
	foreach my $dataset (@$datasets)
	  {
	    $datasetIndex = $self->{DATASETS}->{$dataset};
	    #print "Model: $model Dataset: $dataset\n";
	    my $vect = $self->{RESULTSCLASSIFIEDS}->{$dataset}->{$model}->{$trainProportion};
	    #print join(",",keys %$vect)."\n";
	 
	    my @IdNums = (keys %$vect);
	    my $ERList = zeroes $#IdNums+1;
	    my $LogPList = zeroes $#IdNums+1;
	    my $runIndex = 0;
	    #print "Number of runs: ",$#IdNums + 1,"\n";
	    foreach my $idNum (@IdNums)
	      {
		# Here we treat CV results.
		my $run = $vect->{$idNum};
		#print join(",",keys %$run)."\n";
	 
		my @numFolds = (keys %$run);
		my $runERList =  zeroes $#numFolds+1;
		my $runLogPList = zeroes $#numFolds+1;
		my $foldNumIndex = 0;
		#print "Number of folds = ",$#numFolds + 1,"\n";
		foreach my $foldNum (@numFolds)
		  {
		    #print "Position: $foldNumIndex\n";
		    #print "ER:".$run->{$foldNum}->getErrorRate()."\n";
		    set $runERList,$foldNumIndex,$run->{$foldNum}->getErrorRate();
		    set $runLogPList,$foldNumIndex,$run->{$foldNum}->getLogP();
		    $foldNumIndex++;
		  }
		my ($ERAverage,$ERRMS,$ERMedian,$ERMin,$ERMax) = stats($runERList);
		my ($LogPAverage,$LogPRMS,$LogPMedian,$LogPMin,$LogPMax) = stats($runLogPList);
		
		set $ERList,$runIndex,$ERAverage;
		set $LogPList,$runIndex,$LogPAverage;
		$runIndex++;
	      }
	    my ($ERAverage,$ERRMS,$ERMedian,$ERMin,$ERMax) = stats($ERList);
	    my ($LogPAverage,$LogPRMS,$LogPMedian,$LogPMin,$LogPMax) = stats($LogPList);
	    #print "Average: $ERAverage\n";
	    set $self->{PDLERAVERAGETABLE},$modelIndex,$datasetIndex,$ERAverage;
	    set $self->{PDLERSTDEVTABLE},$modelIndex,$datasetIndex,sqrt($ERRMS);
	    set $self->{PDLLOGPAVERAGETABLE},$modelIndex,$datasetIndex,$LogPAverage;
	    set $self->{PDLLOGPSTDEVTABLE},$modelIndex,$datasetIndex,sqrt($LogPRMS);
	    #$datasetIndex++;
	  }
	#$modelIndex++;
      }
    #my $model = $models->[4];
    #my $piddleA = $self->getAvERDatasets($model);
    #print "$model ER: $piddleA\n"
  }

sub getAvERDatasets
  {
    my ($self,$model)  = @_;
    
    my $modelIndex = $self->{MODELS}->{$model};
    
    my $pdl = $self->{PDLERAVERAGETABLE}->slice("($modelIndex),:");
    #my @l = list $pdl;
    #my $i = 0;
    #foreach my $dataset (@{$self->getDatasets()})
    #  {
#	print "Model: $model. Dataset: $dataset. Results:".$l[$i]."\n";
#	$i ++;
#      }
    return $pdl;
  }

sub getAvLogPDatasets
  {
    my ($self,$model)  = @_;
    
    my $modelIndex = $self->{MODELS}->{$model};
    
    my $pdl = $self->{PDLLOGPAVERAGETABLE}->slice("($modelIndex),:");
    #my @l = list $pdl;
    #my $i = 0;
    #foreach my $dataset (@{$self->getDatasets()})
    #  {
#	print "Model: $model. Dataset: $dataset. Results:".$l[$i]."\n";
#	$i ++;
#      }
    return $pdl;
  }