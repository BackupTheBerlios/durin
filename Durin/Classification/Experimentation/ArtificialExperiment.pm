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

  
  my $runs = $self->getRuns();
  my $inducers = $self->getInducers();
  my $resultDir = $self->getResultDir();
  my $expName = $self->getName();
  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
  my $learningSampleSizes = $self->getLearningSampleSizes();
  my $evaluationCharacteristics = $self->getEvaluationCharacteristics();
  #my $inducedWidths = $self->getInducedWidths();
  
  # Create the model generator
  
  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  
  # Construct the inducer list
  
  my $inducerList = $self->constructInducerList($inducers);
  
  # Create the tester
  
  my $tester = Durin::Classification::Experimentation::ModelTester->create($evaluationCharacteristics);
  #$self->constructTester($evaluationCharacteristics);
  
  # Create the table where we store the results
  
  my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
  
  # For each kind of model specified in the $modelGenerationCharacteristics
  my $modelKinds = $modelGenerator->getModelKinds();
  for my $modelKind (@$modelKinds) {
    for (my $run = 0; $run < $runs ; $run++) {
      $self->executeRun($run,$modelGenerator,$modelKind,$inducerList,$learningSampleSizes,$tester,$resultTable);
    }
    # do something with the result table.
    $resultTable->loadValuesAndAverages();
    $resultTable->writeSummary("$resultDir"."$expName/".$modelKind->{NAME}.".out");
    #$resultTable->summarizeBayes();
    #$resultTable->
  }
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

# End

1;
