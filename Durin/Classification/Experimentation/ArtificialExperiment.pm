#
# This object is the base for artificial experiments from November 2003 on.

package Durin::Classification::Experimentation::ArtificialExperiment;

use base Durin::Classification::Experimentation::Experiment2;
use Class::MethodMaker get_set => [-java => qw/ ModelGenerationCharacteristics LearningSampleSizes EvaluationCharacteristics/];



use Durin::Classification::Experimentation::ResultTable;
use Durin::ModelGeneration::ModelGenerator;
use Durin::Classification::Experimentation::ModelTester;

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

sub run  {   
  my ($self) = @_;
  
  # Get the list of machines where the experiment should work

  my $machines = $self->getMachines();

  # Create the model generator and get the list of model kinds
    
  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  my $modelKinds = $modelGenerator->getModelKinds();
  
  if (@$machines) {
    # We are asked to distribute the work into a list of machines
    $self->distributeWork($modelKinds,$machines);
  } else {
    if ($machines eq "local") {
      # Execute locally
      $self->runLocally($modelKinds,$modelGenerator);
    } else {
      die "You are giving me a single machine and it is not the local one. Are you sure it is not [myremotemachine]?";
    }
  }
}


sub distributeWork {
  my ($self,$modelKinds,$machines) = @_;

  # Distribute experiments in machines
  
  my %controller_pid = {};
  
  foreach my $machine (@$machines) {
    my $pid = $self­>sendJob(shift @$modelKinds,$machine);
    $controller_pid{$pid} = $machine;
    if (scalar(@$modelKinds) == 0) {
      break;
    }
  }
  
  while (scalar(keys %controller_pid) > 0) {
    my $pid = wait();
    my $machine = $controller_pid{$pid};
    delete $controller_pid{$pid};
    if (scalar(@$modelKinds) > 0) {
      my $new_pid = $self­>sendJob(shift @$modelKinds,$machine);
      $controller_pid{$new_pid} = $machine;
    }
  }
}

sub sendJob {
  my ($self,$modelKind,$machine) = @_;
  
  # Write .exp file
  my $expFileName = $self->writeExpFile($modelKind);
  
  # Fork
  my $pid = fork();
  if ($pid == 0) {
    # If you are the son, ask the machine to do the work and wait for it.
    print "Model: ".$modelKind->{NAME}."\n";
    print "Machine to be run at: $machine\n";
    my $traceFileName = $self->getBaseFileName($modelKind).".trace";
    my $remote_cmd = '"RunExperiment.pl '.$expFileName.'>& $traceFileName "';
    my $cmd = "rsh $machine $remote_cmd";
    print "Command: $cmd";
    system($cmd);
    exit;
  } else { # else return the $pid of the son
    return $pid;
  }
}

sub writeExpFile {
  my ($self,$modelKind) = @_;

  my expFileName = $self->baseFileName($modelKind).".exp";
  
}

sub baseFileName {
  my ($self,$modelKind) = @_;
  
  my $resultDir = $self->getResultDir();
  my $expName = $self->getName();
  
  return "$resultDir"."$expName/". $modelKind->{NAME};
}

sub runLocally {
  my ($self,$modelKinds,$modelGenerator)  = @_;
  
  foreach my $modelKind (@$modelKinds) {
    $self->runFixedModelKindExperiment($modelKind,$modelGenerator);
  }
}
  
sub runFixedModelKindExperiment {
  my ($self,$modelKind,$modelGenerator) = @_;
  
  my $runs = $self->getRuns();
  my $inducers = $self->getInducers();
  my $learningSampleSizes = $self->getLearningSampleSizes();
  my $evaluationCharacteristics = $self->getEvaluationCharacteristics();
  
  # Construct the inducer list
  
  my $inducerList = $self->constructInducerList($inducers);
  
  # Create the tester
  
  my $tester = Durin::Classification::Experimentation::ModelTester->create($evaluationCharacteristics);
  
  # Create the table where we store the results
  
  my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  
  for (my $run = 0; $run < $runs ; $run++) {
    $self->executeRun($run,$modelGenerator,$modelKind,$inducerList,$learningSampleSizes,$tester,$resultTable);
  }
  # do something with the result table.
  $resultTable->loadValuesAndAverages();
  my $outFileName = $self->baseFileName($modelKind).".out";
  $resultTable->writeSummary($outFileName);
}

sub constructInducerList {
  my ($self,$inducerNamesList) = @_;
  
  my $inducers = [];
  foreach my $inducerName (@$inducerNamesList)
    {
      push @$inducers,Durin::Classification::Registry->getInducer($inducerName);
    }
  return $inducers;
}

sub executeRun {
  my ($self,$runId,$modelGenerator,$modelKind,$inducerList,$learningSampleSizes,$tester,$resultTable) = @_;
  
  # Generate model
  $modelGenerator->setModelKind($modelKind);
  $modelGenerator->run();
  my $model = $modelGenerator->getOutput()->[0];
  print "Model generated\n";
  $tester->setRealModel($model);
  foreach my $size (@$learningSampleSizes) {
    print "Starting dataset generation\n";
    my $trainingSet = $model->generateDataset($size);
    print "Dataset generated\n";
    print "Started learning\n";
    my $learntModels = $self->learnModels($inducerList,$trainingSet);
    print "Models have been learnt\n";
    print "Started testing\n";
    $self->testModels($runId,$size,$learntModels,$tester,$resultTable);
    print "Testing finished\n";
    print "Summarizing testing info\n";
    $tester->summarize($resultTable);
  }
}

sub learnModels {
  my ($self, $inducerList,$learningSet) = @_;
  
  my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  $bc->setInput({TABLE => $learningSet,
		 ORDER=> 2});
  $bc->run();
  my $countingTable = $bc->getOutput(); 
  
  my $models = [];
  foreach my $inducer (@$inducerList) {
    $inducer->setInput({TABLE => $learningSet, COUNTING_TABLE => $countingTable});
    $inducer->run();
    my $model = $inducer->getOutput();
    #my $tree = $model->getTree();
    #print $inducer->getName()." tree:\n";
    #print $tree->makestring;
    push @$models,$model
  }
  return $models;
}

sub testModels {
  my ($self,$runId,$size,$models,$tester,$resultTable) = @_;
  
  foreach my $model (@$models) {
    my $modelApplication = $tester->test($model);
    $resultTable->addResult($runId,$size,$model->getName(),$modelApplication);
  }
}

sub loadResultsFromFiles {
  my ($self) = @_;

  my $AveragesTable = Durin::Classification::Experimentation::CompleteResultTable->new();
  my $mainDir = $ENV{PWD};
  my $destinationDir = $self->getResultDir().$self->getName();
  print $destinationDir."\n";
  chdir $destinationDir;

  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
  # Create the model generator
  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  
  my $modelKinds = $modelGenerator->getModelKinds();
  for my $modelKind (@$modelKinds) {
    my $name =  $modelKind->{NAME};	
    if (-e $name.".out") {
      print "Taking info from $name\n";
      $self->ProcessResultFile($name,$AveragesTable);
    } else {
      print "$name has not yet been calculated\n";
    }
  }
  chdir $mainDir;
  
  return $AveragesTable;
}

sub getDatasetsByInducer {
  my ($self,$inducer) = @_;

  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
  # Create the model generator
  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  
  my $modelKinds = $modelGenerator->getModelKinds();
  my $datasetList = [];
  foreach my $mk (@{$modelKinds})
    {
      push @$datasetList,$mk->{NAME};
    }
  return $datasetList;
}


# End

1;
