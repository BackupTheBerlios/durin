#
# This object is the base for experiments from November 2003 on.
# An experiment can be ran and generates an structure:
# --- dataset
#   |--- run
#   |  |--- fold
#   |     |--- proportion
#   |        |--- model-name.out
#   |--- summary.out ? (not decided yet.
#
# data.out has the following structure:
# 
# CLASS [0..numclasses-1], ALGORITHM 1 PROBABILITY FOR CLASS 0,..., ALGORITHM 1 PROBABILITY FOR CLASS numclasses-1, ..., ALGORITHM k PROBABILITY FOR CLASS numclasses-1
# 
# summary.out has the following structure:
# RUN, FOLD, PROPORTION, ALGORITHM 1 ER, ALGORITHM 1 LogP, ALGORITHM 1 AUC, ..., ALGORITHM k AUC

package Durin::Classification::Experimentation::Experiment2;

use base Durin::Components::Process;
use Class::MethodMaker get_set => [-java => qw/ Name DataDir ResultDir DurinDir Tasks Folds Runs Proportions DiscMethod DiscIntervals Inducers Dataset LaTexTablePrefix Machine Evaluator/];

use Durin::Classification::Experimentation::ResultTable;
use strict;
use warnings;

use PDL;

sub new_delta 
  {
    my ($class,$self) = @_;
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
      
    die "Durin::Classification::Experimentation::Experiment2::clone not implemented\n";
  }

# The task list is stored as expressed 
# by the following example:
# my @taskList = (
#		["adult",{inducers => ["IndifferentNB","TAN+MS","SSTBMATAN"]}],		
#		["breast"],
#		["car"],
#		["chess",{inducers => ["IndifferentNB","TAN+MS","SSTBMATAN"]}],
#		["cleve"],
#		["crx"],
#		["flare"],
#		["glass"],
#		["hep"],
#		["iris"],
#		["letter",{folds=>2,runs=>1,inducers => ["IndifferentNB","TAN+MS","SSTBMATAN"]}],
#		["mushroom",{folds=>2, runs=>1,inducers => ["IndifferentNB","TAN+MS","SSTBMATAN"]}],
#		["nursery",{folds=>2,runs=>1,inducers => ["IndifferentNB","TAN+MS","SSTBMATAN"]}],
#		["pima"],
#		["soybean"],
#		["votes"],
#	       );

sub processTaskList {
  my ($self,$taskList) = @_;
  
  my $tasks = [];
  foreach my $task (@$taskList)
    {
      my $t = Durin::Classification::Experimentation::Experiment2->new();
      $t->setDataset($task->[0]);
      if (scalar(@$task)>1) {
	my $optHash = $task->[1];
	if (exists $optHash->{data_dir}) {
	  $t->setDataDir($optHash->{data_dir});
	}	
	if (exists $optHash->{result_dir}) {
	  $t->setResultDir($optHash->{result_dir});
	}	
	if (exists $optHash->{durin_dir}) {
	  $t->setDurinDir($optHash->{durin_dir});
	}
	if (exists $optHash->{folds}) {
	  $t->setFolds($optHash->{folds});
	}
	if (exists $optHash->{runs}) {
	  $t->setRuns($optHash->{runs});
	}	
	if (exists $optHash->{proportions}) {
	  $t->setProportions($optHash->{proportions});
	}
	if (exists $optHash->{disc_method}) {
	  $t->setDiscMethod($optHash->{disc_method});
	}	
	if (exists $optHash->{disc_intervals}) {
	  $t->setDiscIntervals($optHash->{disc_intervals});
	}
	if (exists $optHash->{inducers}) {
	  $t->setInducers($optHash->{inducers});
	}
	if (exists $optHash->{machine}) {
	  $t->setMachine($optHash->{machine});
	}
	if (exists $optHash->{evaluator}) {
	  $t->setMachine($optHash->{evaluator});
	}
	
      }
      push @$tasks,$t;
    }
  $self->setTasks($tasks);
}

sub run
{
  my ($self) = @_;
  
  foreach my $task (@{$self->getTasks()})
    {
      $self->runTask($task);
    }
}

sub runTask {
  my ($self,$action) = @_;
  
  my $dataset = $action->getDataset();
  
  my $folds = $self->getFolds();
  if ($action->getFolds())
    {
      $folds = $action->getFolds();
    }

  my $runs = $self->getRuns();
  if ($action->getRuns())
    {
      $runs = $action->getRuns();
    }

  my $proportions = $self->getProportions();
  if ($action->getProportions())
    {
      $proportions = $action->getProportions();
    }
 
  my $discMethod = $self->getDiscMethod();
  if ($action->getDiscMethod())
    {
      $discMethod = $action->getDiscMethod();
    }
  
  my $discIntervals = $self->getDiscIntervals();
  if ($action->getDiscIntervals())
    {
      $discIntervals = $action->getDiscIntervals();
    }
  
  my $inducers = $self->getInducers();
  if ($action->getInducers())
    {
      $inducers = $action->getInducers();
    }

  my $machine = $self->getMachine();
  if ($action->getMachine())
    {
      $machine = $action->getMachine();
    } 

  my $evaluator = $self->getEvaluator();
  if ($action->getEvaluator())
    {
      $evaluator = $action->getEvaluator();
    }

  my $dataDir = $self->getDataDir();
  my $resultDir = $self->getResultDir();
  my $expName = $self->getName();
  
  # Prepare for writing the experiment file

  my $proportionsString = join(" ",@$proportions); 
  my $inducersString = '"'.join('","',@$inducers).'"';
  my $datasetWithDir = $dataDir.$dataset."/".$dataset.".std";
  my $resultFile = $resultDir.$expName."/".$dataset;
  my $DurinDir = $self->getDurinDir();
  
  # Write the experiment file
  my $file = IO::File->new();
  if (!$file->open(">$resultFile.exp")) {
    die "Impossible to open $resultFile.exp\n";
  }
  $file->print("\$numFolds = $folds;
\$numRepeats = $runs;
\@proportionList = qw($proportionsString);
\$inFileName = \"$datasetWithDir\";
\$outFileName = \"$resultFile.out\";
\$discOptions->{DISCMETHOD} = \"$discMethod\";
\$discOptions->{NUMINTERVALS} = $discIntervals;
\$totalsOutFileName = \"$resultFile.totals\";
\$inducerNamesList = [$inducersString];
\$outDir = \"$resultFile\";");
  $file->close();

  $self->launchDatasetExperiment($machine,$dataDir,$dataset,$DurinDir,$evaluator,$resultFile);
}

sub launchDatasetExperiment {
  my ($self,$machine,$dataDir,$dataset,$DurinDir,$evaluator,$resultFile) = @_;

  if ($machine eq "local")
    {
      # If it has to be run locally
      # Get to the place where the dataset is
      
      chdir $dataDir."/".$dataset;
      
      # Execute the action
      
      print "Executing for dataset ".$dataset."\n";
      my $command = "perl -w $DurinDir".$evaluator." $resultFile.exp > $resultFile.trace";
      print "Command: $command\n";
      system($command);
      print "Finished execution for dataset ".$dataset."\n";
    }
  else {
    # If the user indicated a machine where the experiments should be run
    # we use rsh to send the task to the machine
    
    print "Machine to be executed in: $machine\n";
    my $command = "\"cd $dataDir"."$dataset; perl -w $DurinDir".$evaluator." $resultFile.exp > $resultFile.trace\" & ";
    $command = "rsh $machine $command";
    print "Command: $command\n";
    system($command);
  }
}

sub getDatasetsByInducer {
  my ($self,$inducer) = @_;
  
  my $datasetList = [];
  foreach my $t (@{$self->getTasks()})
    {
      my $inducers = $self->getInducers();
      if ($t->getInducers())
	{
	  $inducers = $t->getInducers();
	}

      my $isInTask = grep $_ eq $inducer, @$inducers;
      if ($isInTask) {
	push @$datasetList,$t->getDataset();
      }
    }
  return $datasetList;
}






















sub loadResultsFromFiles {
  my ($self) = @_;

  my $AveragesTable = Durin::Classification::Experimentation::CompleteResultTable->new();
  my $mainDir = $ENV{PWD};
  my $destinationDir = $self->getResultDir().$self->getName();
  print $destinationDir."\n";
  chdir $destinationDir;
  foreach my $task (@{$self->getTasks()}) {
    my $dataset = $task->getDataset();
    if (-e "$dataset.out") {
      print "Taking info from to dataset $dataset\n";
      $self->ProcessResultFile($dataset,$AveragesTable);
    } else {
      print "Dataset $dataset has not yet been calculated\n";
    }
  }
  chdir $mainDir;

  return $AveragesTable;
}

sub ProcessResultFile {
  my ($self,$dataset,$AveragesTable) = @_;
  
  my $file = new IO::File;
  $file->open("<$dataset.out") or die "Unable to open $dataset.out\n";
  
  # read the headers (the field names)
  my $line = $file->getline();
  my @decompLine = split(/,/,$line);
  if (!($decompLine[0] eq "Fold")) {
    die "File $dataset.out has not the format required\n";
  }
  
  my $i = 2;
  my $modelList = ();
  while ($i < $#decompLine) {
    push @$modelList,(substr($decompLine[$i],2));
    $i += 4;
  }
  
  #my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  do {
    $line = $file->getline();
    my @array = split(/,/,$line);
    $i = 0;
    my $runId = $array[0];
    my $proportion = $array[1];
    #print "Proportion: $proportion\n";
    foreach my $modelName (@$modelList) {
      my $OKs = $array[$i * 4 + 2];
      my $Wrongs = $array[$i * 4 + 3];
      my $PLog = $array[$i *4 + 5];
      #print "Next One: $modelName $runId $OKs $Wrongs $PLog\n";
      #getc;
      my $PMA = Durin::ProbClassification::ProbModelApplication->new();
      $PMA->setNumOKs($OKs);
      $PMA->setNumWrongs($Wrongs);
      $PMA->setLogP($PLog);
      
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
      if ($self->checkModel($modelName)) {
	  $AveragesTable->addResult($dataset,$idNum,$foldNum,$proportion,$modelName,$PMA);
      }
      $i++; 
  }
} until ($file->eof());
  $file->close();
}

sub checkModel {
    my($self,$modelName) = @_;

    my $contained = 0;
    foreach my $name (@{$self->getInducers()}) {
	$contained = $contained || ($name eq $modelName);
    }
    return $contained;
}

sub summarize {
  my ($self) = @_;
  
  foreach my $task (@{$self->getTasks()})
    {
      $self->summarizeTask($task);
    }
}

sub summarizeTask {
  my ($self,$action) = @_;

  my $dataset = $action->getDataset();
  my $resultDir = $self->getResultDir();
  my $expName = $self->getName();
  my $resultFile = $resultDir.$expName."/".$dataset;
  
  my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  print "Reading data from dataset $dataset\n";
  $resultTable->readFromFile($resultFile);
  print "Summarizing dataset $dataset\n";
  $resultTable->summarize();
  $resultTable->writeSummary("$resultFile.out");
}


1;
