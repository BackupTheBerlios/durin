#
# This object implements the functionality needed to run a set of inducers over a set of models randomly generated from a family with some characteristics.
#

package Durin::Classification::Experimentation::ArtificialTask::EvaluationCharacteristics;
use Durin::Classification::Experimentation::Experiment3;
push @ISA,'Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics';
use Class::MethodMaker
  get_set => [-java => qw/ Type TestingSampleSize LearningSampleSizes/];


package Durin::Classification::Experimentation::ArtificialTask;

use base Durin::Classification::Experimentation::Experiment3;
use Class::MethodMaker get_set => [-java => qw/ ModelKind ModelGenerationCharacteristics/];
use Durin::Classification::System;
use Durin::Classification::Registry;
use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::ModelTesterFactory;

use Env qw(DURIN_HOME);

use strict;
use warnings;

sub init {
  my ($self,%properties) = @_;
  
  # $self->SUPER::init(%properties);

  my $ev_c = Durin::Classification::Experimentation::ArtificialTask::EvaluationCharacteristics->new(%{$self->getEvaluationCharacteristics()});
  $self->setEvaluationCharacteristics($ev_c);
}

sub run {
  my ($self)  = @_;
  
  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  
  my $inducers = $self->getInducers();
  my $modelKind = $self->getModelKind();
  my $evaluationCharacteristics = $self->getEvaluationCharacteristics();
  my $learningSampleSizes = $evaluationCharacteristics->getLearningSampleSizes();
  my $runs = $evaluationCharacteristics->getRuns();
  #$self->getExecutionCharacteristics()
  # Construct the inducer list
  
  my $inducerList = $self->constructInducerList($inducers);
  
  # Create the tester
  
  my $tester = Durin::Classification::Experimentation::ModelTesterFactory->create($evaluationCharacteristics);
  
  # Create the table where we store the results
  
  my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  
  for (my $run = 0; $run < $runs ; $run++) {
    $self->executeRun($run,$modelGenerator,$modelKind,$inducerList,$learningSampleSizes,$tester,$resultTable);
  }
  # do something with the result table.
  $resultTable->loadValuesAndAverages();
  my $outFileName = $self->getBaseFileName().".out";
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

sub getFixedCharacteristics {
  my ($self) = @_;

  my $fixed_characteristics = $self->SUPER::getFixedCharacteristics();
  my $options = Durin::ModelGeneration::ModelGenerator->getModelKindOptions($self->getModelKind());
  foreach my $key (keys %$options) {
    push @$fixed_characteristics, [$key,$options->{$key}];
  }
  return $fixed_characteristics;
}

#sub loadResultsFromFiles {
#  my ($self) = @_;

#  my $AveragesTable = Durin::Classification::Experimentation::CompleteResultTable->new();
#  my $mainDir = $ENV{PWD};
#  my $destinationDir = $self->getResultDir().$self->getName();
#  print $destinationDir."\n";
#  chdir $destinationDir;

#  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
#  # Create the model generator
#  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  
#  my $modelKinds = $modelGenerator->getModelKinds();
#  for my $modelKind (@$modelKinds) {
#    my $name =  $modelKind->{NAME};	
#    if (-e $name.".out") {
#      print "Taking info from $name\n";
#      $self->ProcessResultFile($name,$AveragesTable);
#    } else {
#      print "$name has not yet been calculated\n";
#    }
#  }
#  chdir $mainDir;
  
#  return $AveragesTable;
#}

#sub getDatasetsByInducer {
#  my ($self,$inducer) = @_;

#  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
#  # Create the model generator
#  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  
#  my $modelKinds = $modelGenerator->getModelKinds();
#  my $datasetList = [];
#  foreach my $mk (@{$modelKinds})
#    {
#      push @$datasetList,$mk->{NAME};
#    }
#  return $datasetList;
#}


# End
