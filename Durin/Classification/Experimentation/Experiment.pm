# Object that describes and experiment
#

package Durin::Classification::Experimentation::Experiment;

use base Durin::Components::Process;
use Class::MethodMaker get_set => [-java => qw/ Name DataDir ResultDir DurinDir Tasks Folds Runs Proportions DiscMethod DiscIntervals Inducers Dataset/];

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
    
    die "Durin::Classification::Experimentation::Experiment::clone not implemented\n";
  }

# The task list is stored as expressed 
# by the following example:
#my @taskList = (
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
      my $t = Durin::Classification::Experimentation::Experiment->new();
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
  $file->open(">$resultFile.exp");
  $file->print("\$numFolds = $folds;
\$numRepeats = $runs;
\@proportionList = qw($proportionsString);
\$inFileName = \"$datasetWithDir\";
\$outFileName = \"$resultFile.out\";
\$discOptions->{DISCMETHOD} = \"$discMethod\";
\$discOptions->{NUMINTERVALS} = $discIntervals;
\$totalsOutFileName = \"$resultFile.totals\";
\$inducerNamesList = [$inducersString];");
  $file->close();
  
  # Get to the place where the dataset is

  chdir $dataDir."/".$dataset;

  # Execute the action

  print "Executing for dataset ".$dataset."\n";
  my $command = "perl -w $DurinDir"."scripts/IndComp.pl $resultFile.exp > $resultFile.trace";
  print "Command: $command\n";
  system($command);
  print "Finished execution for dataset ".$dataset."\n";
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
      $AveragesTable->addResult($dataset,$idNum,$foldNum,$proportion,$modelName,$PMA);
      $i++; 
    }
  } until ($file->eof());
  $file->close();
}

1;
