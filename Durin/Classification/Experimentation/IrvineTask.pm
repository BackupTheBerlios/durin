#
# This object implements the functionality needed to run a set of inducers over a Irvine dataset
#
# TODO:Still relies on IndComp.pl. Remove that.

#package Durin::Classification::Experimentation::IrvineTask::EvaluationCharacteristics;
#require Durin::Classification::Experimentation::Experiment3;
#push @ISA,'Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics';
#use Class::MethodMaker
#  get_set => [-java => qw//];

#package Durin::Classification::Experimentation::IrvineTask::ExecutionCharacteristics;
#require Durin::Classification::Experimentation::Experiment3;
#push @ISA,'Durin::Classification::Experimentation::Experiment3::ExecutionCharacteristics';
#use Class::MethodMaker
#  get_set => [-java => qw/ DataDir/];

package Durin::Classification::Experimentation::IrvineTask;

use base Durin::Classification::Experimentation::Experiment3;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Dataset  Datasets/];

use Durin::Classification::Experimentation::ResultTable;

use Env qw(DURIN_HOME);

use strict;
use warnings;

sub init {
  my ($self,%properties) = @_;
  
  #print "Initializing Irvine task\n";
  $self->SUPER::init(%properties);
  
 # my $ev_c = Durin::Classification::Experimentation::IrvineTask::EvaluationCharacteristics->new($self->getEvaluationCharacteristics());
#  $self->setEvaluationCharacteristics($ev_c);
  
#  my $ex_c = Durin::Classification::Experimentation::IrvineTask::ExecutionCharacteristics->new($self->getExecutionCharacteristics());
#  $self->setExecutionCharacteristics($ex_c);
}

sub run {
  my ($self) = @_;
  
  my $dataset = $self->getDataset();
  
  # Get all the charaateristics of the evaluation
  
  my $evaluationCharacteristics = $self->getEvaluationCharacteristics();
  
  my $folds = $evaluationCharacteristics->getFolds();
  my $runs = $evaluationCharacteristics->getRuns();
  my $proportions = $evaluationCharacteristics->getProportions();
  my $discMethod = $evaluationCharacteristics->getDiscMethod();
  my $discIntervals = $evaluationCharacteristics->getDiscIntervals();
  my $evaluator = $evaluationCharacteristics->getEvaluator();
  
  my $dataDir = $self->getExecutionCharacteristics()->getDataDir();
  
  my $inducers = $self->getInducers();
  #my $machine = $self->getMachine();
  my $resultDir = $self->getResultDir();
  my $expName = $self->getName();
  my $DurinDir = $self->getDurinDir();
  if (!defined $DurinDir) {
    $DurinDir = $DURIN_HOME;
  }
  # Prepare for writing the experiment file
  
  my $proportionsString = join(" ",@$proportions); 
  my $inducersString = '"'.join('","',@$inducers).'"';
  my $datasetWithDir = $dataDir.$dataset."/".$dataset.".std";
  my $resultFile = $self->getBaseFileName();
  
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
  
  $self->launchDatasetExperiment($dataDir,$dataset,$DurinDir,$evaluator,$resultFile);
}

sub launchDatasetExperiment {
  my ($self,$dataDir,$dataset,$DurinDir,$evaluator,$resultFile) = @_;

  #if ($machine eq "local")
  #  {
  # If it has to be run locally
  # Get to the place where the dataset is
  
  chdir $dataDir."/".$dataset;
  
  # Execute the action
  
  print "Executing for dataset ".$dataset."\n";
  my $command = "perl -w $DurinDir".$evaluator." $resultFile.exp > $resultFile.trace";
  print "Command: $command\n";
  system($command);
  print "Finished execution for dataset ".$dataset."\n";
#    }
#  else {
#    # If the user indicated a machine where the experiments should be run
#    # we use rsh to send the task to the machine
#    
#    print "Machine to be executed in: $machine\n";
#    my $command = "\"cd $dataDir"."$dataset; perl -w $DurinDir".$evaluator." $resultFile.exp > $resultFile.trace\" ";
#    $command = "rsh $machine $command";
#    print "Command: $command\n";
#    system($command);
#  }
}

sub summarize {
  my ($self) = @_;

  my $dataset = $self->getDataset();
  my $resultDir = $self->getResultDir();
  my $expName = $self->getName();

  my $resultFile = $self->getBaseFileName();

  my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  print "Reading data from dataset $dataset and summarizing\n";
  #$resultTable->readFromFile($resultFile);
  #print "Summarizing dataset $dataset\n";
  $resultTable->readFromFileAndSummarize($resultFile);
  $resultTable->writeSummary("$resultFile.out");
}


  
#sub checkModel {
  #    my($self,$modelName) = @_;
  
  #    my $contained = 0;
  #    foreach my $name (@{$self->getInducers()}) {
  #	$contained = $contained || ($name eq $modelName);
#    }
#    return $contained;
#}



1;

