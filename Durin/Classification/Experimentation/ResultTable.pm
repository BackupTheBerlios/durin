# Contains the table of results that summarizes an experiment. That means it has:
# 
#  Method x Percentage x RunNumber
#

package Durin::Classification::Experimentation::ResultTable;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use Durin::Classification::Experimentation::AUCModelApplication;

use strict;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    $self->{RESULTLIST} = [];
    $self->{RESULTSCLASSIFIEDS} = {};
    $self->{PROPORTIONS} = {};
    $self->{MODELS} = {};
    $self->{AVERAGES_TABLE} = {};
    $self->{VALUES_TABLE} = {};
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    die "Durin::Classification::Experimentation::ResultTable::clone not implemented\n";
  }


sub addResult
  {
    my ($self,$runId,$trainProportion,$modelName,$modelApplication) = @_;
    
    if (!(exists $self->{PROPORTIONS}->{$trainProportion}))
      {
	$self->{PROPORTIONS}->{$trainProportion} = undef;
      }
    if (!(exists $self->{MODELS}->{$modelName}))
      {
	$self->{MODELS}->{$modelName} = undef;
      }
    
    # print $model->getName(),"\n";
    push @{$self->{RESULTLIST}},([$runId,$trainProportion,$modelName,$modelApplication]);
    $self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}->{$modelName} = $modelApplication;
  }

sub getResult
  {
    my ($self,$runId,$trainProportion,$modelName) = @_;

    return $self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}->{$modelName};
  }

sub getResults
  {
    my ($self) = @_;
    
    return $self->{RESULTLIST};
  }

sub getResultsByModel
  {
    my ($self) = @_;
    
    my @resultList = ();   
    foreach my $runId (keys %{$self->{RESULTSCLASSIFIEDS}})
      {
	foreach my $trainProportion (keys %{$self->{RESULTSCLASSIFIEDS}->{$runId}})
	  {
	    my @runList = ();
	    foreach my $model (sort (keys %{$self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}}))
	      {
		push @runList,([$model,$self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}->{$model}]);
	      }
	    push @resultList,([$runId,$trainProportion,\@runList]);
	  }
      }
    return \@resultList;
  }

sub getProportions
  {
    my ($self) = @_;
    
    my @list = (sort (keys %{$self->{PROPORTIONS}}));
    return \@list;
  }

sub getModels
  {
    my ($self) = @_;
    
    my @list = (sort (keys %{$self->{MODELS}}));
    return \@list;
  }

sub write {
  my ($self,$outDir) = @_;
  
  if (!(-d $outDir)) {
    mkdir $outDir;
  }
  print "Writing\n";
  foreach my $runId (keys %{$self->{RESULTSCLASSIFIEDS}}) {
    
    my $runIdDirName =  $outDir."/$runId";
    if (!(-d $runIdDirName)) {
      mkdir $runIdDirName;
    }
    foreach my $proportion (keys %{$self->{RESULTSCLASSIFIEDS}->{$runId}}) {
      my $propDirName =  $runIdDirName."/$proportion";
      if (!(-d $propDirName)) {
	mkdir $propDirName;
      }
      foreach my $model (keys %{$self->{RESULTSCLASSIFIEDS}->{$runId}->{$proportion}}) {
	my $AUCModelApplication = $self->getResult($runId,$proportion,$model);
	$AUCModelApplication->write("$propDirName/$model.out");
      }
    }
  }
}

sub readFromFile {
  my ($self,$inDir) = @_;
  
  #if (!(-d $inDir)) {
  #  die "Unable to find directory $inDir\n";
  #}
  print "Reading result Table\n";
  opendir(RUNIDDIR, $inDir) || die "Unable to find directory $inDir\n";
  my @runIds = grep {/^[^\.]/} readdir(RUNIDDIR);
  foreach my $runId (@runIds)
    {
      #unless ( ($runId eq ".") || ($runId eq "..") )
      #{ 
      my $propDirName = $inDir."/".$runId;
      opendir(PROPDIR,$propDirName);
      my @proportions = grep {/^[^\.]/}readdir(PROPDIR);
      foreach my $proportion (@proportions) 
	{
	  my $modelDirName = $propDirName."/".$proportion;
	  opendir(MODELDIR,$modelDirName);
	  my @models = grep {/^[^\.]/}readdir(MODELDIR);
	  foreach my $modelFile (@models) {
	    my $modelApplication = Durin::Classification::Experimentation::AUCModelApplication->new();
	    $modelApplication->readFromFile($modelDirName."/".$modelFile);
	    $modelFile =~ /(.*)\.out/;
	    my $model = $1;
	    $self->addResult($runId,$proportion,$model,$modelApplication);
	  }
	  closedir(MODELDIR);
	}
      closedir(PROPDIR);
    }
  closedir(RUNIDDIR);
}

# Construct a single data structure containing all runs of different classifiers on a dataset

sub summarize {
  my ($self) = @_;

  foreach my $propResult (@{$self->getResultsByModel()}) {
    my $fold = $propResult->[0];
    my $proportion = $propResult->[1];	
    my $PMAList = $propResult->[2];
    
    foreach my $PMAPair (@$PMAList) {
      my $model = $PMAPair->[0];
      my $PMA = $PMAPair->[1];
      print "$model results\n";
      $PMA->summarize();
    }
  }
  $self->loadValuesAndAverages();
}

sub summarizeBayes {
  my ($self) = @_;

  foreach my $propResult (@{$self->getResultsByModel()}) {
    my $fold = $propResult->[0];
    my $proportion = $propResult->[1];	
    my $PMAList = $propResult->[2];
    
    foreach my $PMAPair (@$PMAList) {
      my $model = $PMAPair->[0];
      my $PMA = $PMAPair->[1];
      $PMA->summarizeBayes();
    }
  }
  $self->loadValuesAndAverages();
}

sub loadValuesAndAverages {
  my ($self) = @_;
  
  my ($AveragesTable,$valuesTable);
 
  my $modelList = $self->getModels();
  my $proportionList = $self->getProportions();

  foreach my $model (@$modelList)
    {
      foreach my $proportion (@$proportionList)
	{
	  #$AveragesTable->{$model}->{$proportion}->{OKS} = 0;
	  #$AveragesTable->{$model}->{$proportion}->{WRONGS} = 0;
	  $AveragesTable->{$model}->{$proportion}->{ERRORRATE} = 0;
	  $AveragesTable->{$model}->{$proportion}->{LOGP} = 0;	
	  $AveragesTable->{$model}->{$proportion}->{AUC} = 0;	
	  #$AveragesTable->{$model}->{$proportion}->{OKSLIST} = ();
	  #$AveragesTable->{$model}->{$proportion}->{WRONGSLIST} = ();
	  $AveragesTable->{$model}->{$proportion}->{ERRORRATELIST} = ();
	  $AveragesTable->{$model}->{$proportion}->{LOGPLIST} = (); 
	  $AveragesTable->{$model}->{$proportion}->{AUCLIST} = ();
	  $AveragesTable->{$model}->{$proportion}->{N} = 0;
	}
    }
  
  # write the contents

  foreach my $propResult (@{$self->getResultsByModel()})
    {
      my $fold = $propResult->[0];
      my $proportion = $propResult->[1];	
      my $PMAList = $propResult->[2];

      foreach my $PMAPair (@$PMAList)
	{
	  my $model = $PMAPair->[0];
	  my $PMA = $PMAPair->[1];
	  #$PMA->summarize();
	  #$AveragesTable->{$model}->{$proportion}->{OKS} += $PMA->getNumOKs();
	  #$AveragesTable->{$model}->{$proportion}->{WRONGS} += $PMA->getNumWrongs();
	  #print "$model-$proportion\n";
	  $AveragesTable->{$model}->{$proportion}->{ERRORRATE} += $PMA->getErrorRate();	
	  $AveragesTable->{$model}->{$proportion}->{LOGP} += $PMA->getLogP();	
	  $AveragesTable->{$model}->{$proportion}->{AUC} += $PMA->getAUC();
	  $valuesTable->{$fold}->{$proportion}->{$model}->{ERRORRATE} = $PMA->getErrorRate();	
	  $valuesTable->{$fold}->{$proportion}->{$model}->{LOGP} = $PMA->getLogP();	
	  $valuesTable->{$fold}->{$proportion}->{$model}->{AUC} = $PMA->getAUC();
	  $AveragesTable->{$model}->{$proportion}->{N} += 1;
	  
	  push @{$AveragesTable->{$model}->{$proportion}->{ERRORRATELIST}}, $PMA->getErrorRate();	
	  push @{$AveragesTable->{$model}->{$proportion}->{LOGPLIST}}, $PMA->getLogP();
	  push @{$AveragesTable->{$model}->{$proportion}->{AUCLIST}}, $PMA->getAUC();
	  #print ($AveragesTable->{$model}->{$proportion}->{N},"\n");
	  #print ($model,",",$proportion,"\n");
	}
    }
  $self->{AVERAGES_TABLE} = $AveragesTable;
  $self->{VALUES_TABLE} = $valuesTable
}



# Drops the summary information in a single file

sub writeSummary {
  my ($self,$outFileName)  = @_;
  
  # Write the output file
  
  my $file = new IO::File;
  $file->open(">$outFileName") or die "Unable to open $outFileName\n";
  
  # write  the headers (the field names) and initialize averages table.
  
  my $AveragesTable;
  print $file "Fold,Proportion";
  my $modelList = $self->getModels();
  my $proportionList = $self->getProportions();
  foreach my $model (@$modelList)
    {
      print $file ",ER".$model.",LP".$model.",AUC".$model;
    }
  print $file "\n";
  
  # write the contents
  
  my $valuesTable = $self->{VALUES_TABLE};
  foreach my $fold (keys %$valuesTable) {
    foreach my $proportion (keys %{$valuesTable->{$fold}}) {
      print $file $fold.",".$proportion;
      foreach my $model (@$modelList) {
	print $file ",".$valuesTable->{$fold}->{$proportion}->{$model}->{ERRORRATE};
	print $file ",".$valuesTable->{$fold}->{$proportion}->{$model}->{LOGP};
	print $file ",".$valuesTable->{$fold}->{$proportion}->{$model}->{AUC};
      }
      print $file "\n";
    }
  }
  $file->close();

  $self->writeAverages($outFileName.".totals");
}

sub writeAverages {
  my ($self,$outFileName) = @_;
  
  # Write the totals output file
  my $file = new IO::File;
  $file->open(">$outFileName") or die "Unable to open $outFileName\n";
  
  print $file "AVERAGES\n";
  print $file "--------\n";
  
  my $modelList = $self->getModels();
  my $proportionList = $self->getProportions();
  my $AveragesTable = $self->{AVERAGES_TABLE};
  foreach my $proportion (@$proportionList)
    {
      #print $file ("AVERAGE,",$proportion);
      print $file "Proportion: $proportion\n";
      foreach my $model (@$modelList)
	{
	  my $AT = $AveragesTable->{$model}->{$proportion};
	  my %StDev;
	  $AT->{ERRORRATE} = $AT->{ERRORRATE} / $AT->{N};
	  $StDev{ERRORRATE} = Durin::Utilities::MathUtilities::StDev($AT->{ERRORRATE},$AT->{ERRORRATELIST});
	  $AT->{LOGP} = $AT->{LOGP} / $AT->{N};
	  $StDev{LOGP} = Durin::Utilities::MathUtilities::StDev($AT->{LOGP},$AT->{LOGPLIST});
	  $AT->{AUC} = $AT->{AUC} / $AT->{N};
	  $StDev{AUC} = Durin::Utilities::MathUtilities::StDev($AT->{AUC},$AT->{AUCLIST});
	
	  print $file ($model,":[ERRORRATE:",$AT->{ERRORRATE},"+-",$StDev{ERRORRATE},"],[LOGP:",$AT->{LOGP},"+-",$StDev{LOGP},"]",",[AUC:",$AT->{AUC},"+-",$StDev{AUC},"]\n");
	}
      print $file "\n";
    }
  $file->close();
}

# Load the summary information from a simple file

sub loadSummary {  
  my ($self,$fileName,$taskName) = @_;
  
  my $file = new IO::File;
  $file->open("<$fileName") or die "Unable to open $fileName\n";
  
  # read the headers (the field names)
  my $line = $file->getline();
  chomp $line;
  my @decompLine = split(/,/,$line);
  if (!($decompLine[0] eq "Fold")) {
    die "File $fileName has not the format required\n";
  }
  
  my $i = 2;
  my $modelList = ();
  while ($i < $#decompLine) {
    push @$modelList,(substr($decompLine[$i],2));
    $i += 3;
  }
  
  #my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  do {
    $line = $file->getline();
    chomp $line;
    my @array = split(/,/,$line);
    $i = 0;
    my $runId = $array[0];
    my $proportion = $array[1];
    #print "Proportion: $proportion\n";
    foreach my $modelName (@$modelList) {
      #my $OKs = $array[$i * 4 + 2];
      #my $Wrongs = $array[$i * 4 + 3];
      my $ER = $array[$i * 3 + 2];
      my $LogP = $array[$i * 3 + 3];
      my $AUC = $array[$i * 3 + 4];
      
      #print "Next One: $modelName $runId $ER $AUC $LogP\n";
      #getc;
      my $PMA = Durin::ProbClassification::ProbModelApplication->new();
      $PMA->setErrorRate($ER);
      $PMA->setLogP($LogP);
      $PMA->setAUC($AUC);
      
      # Check for CV results
      
      my ($idNum,$foldNum);
      if ($runId =~ /(.*)\.(.*)/) {
	$idNum = $1;
	$foldNum = $2;
      } else {
	$idNum = $runId;
	$foldNum = 0;
      }
      #Check if the model is in the actual model list
      #if ($self->checkModel($modelName)) {
      $self->addResult("$idNum.$foldNum",$proportion,$modelName,$PMA);
      #      }
      $i++; 
    }
  } until ($file->eof());
  $file->close();
}

#for (my $thisRepetition = 0; $thisRepetition < $numRepeats ; $thisRepetition++) {
#    my $repDirName =  $outDir."/$thisRepetition";
#    if (!(-d $repDirName)) {
#      mkdir $repDirName;
#    }
#    for (my $thisFold = 0; $thisFold < $numFolds ; $thisFold++) {
#      my $foldDirName =  $repDirName."/$thisFold";
#      if (!(-d $foldDirName)) {
#	mkdir $foldDirName;
#      }
#      my $runId = $thisRepetition.".".$thisFold;
#      foreach my $proportion (@proportionList) {
#	my $propDirName =  $foldDirName."/$proportion";
#	if (!(-d $propDirName)) {
#	  mkdir $propDirName;
#	}
#	my $modelList = $resultTable->getModels();
#	foreach my $model (@$modelList)
#	  {
#	    my $AUCModelApplication = $resultTable->getResult($runId,$proportion,$model);
#	    $AUCModelApplication->write("$propDirName/$model.out");
#	  }
#      }
#    }
#  }

sub dumpToSQLiteFile {
  my ($self,$file,$attributes_list) = @_;
  
  # write the contents
  
  my $line_fixed = "";
  foreach my $pair (@$attributes_list) {
    $line_fixed = $line_fixed.writeValue($pair->[1]).",";
  }
  
  foreach my $result (@{$self->{RESULTLIST}}) {
    my ($runId,$trainProportion,$modelName,$modelApplication) = @$result;
    my ($run,$fold) = split(/\./,$runId);
    my $wrun = writeValue($run);
    my $wfold = writeValue($fold);
    my $line  = $line_fixed."$wrun,$wfold";
    my $wproportion = writeValue($trainProportion);
    $line  = $line.",$wproportion";
    my $wmodel = writeValue($modelName);
    $line = $line.",$wmodel";
    #print "$line\n";
    $line= $line.",".writeValue($modelApplication->getErrorRate());
    $line= $line.",".writeValue($modelApplication->getLogP());
    $line= $line.",".writeValue($modelApplication->getAUC())."\n";
    
    #foreach my $measure (@$measures) {
    #  $line = $line.",".writeValue($valuesTable->{$runId}->{$proportion}->{$model}->{$measure});
    #}
    print $file $line;
    #print $line;
  }
}

sub writeValue {
  my ($value) = @_;
  if (!defined $value) {
    return "\\N"; 
  } else {
    return $value;
  }
}

sub getMeasures {
  return ["ERRORRATE","LOGP","AUC"];
}
1;
