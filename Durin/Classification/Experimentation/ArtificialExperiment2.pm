#
# This object is the base for artificial experiments from January 2004 on.

package Durin::Classification::Experimentation::ArtificialExperiment2;

use base Durin::Classification::Experimentation::CompositeExperiment;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ ModelGenerationCharacteristics ModelKind/];

use Durin::Classification::Experimentation::ArtificialTask;
use Durin::ModelGeneration::ModelGenerator;
use Data::Dumper;

use strict;
use warnings;

sub init {
  my ($self,%properties) = @_;
  
  $self->SUPER::init(%properties);
  
  print "Initializing artificial experiment\n";
 # my $ev_c = Durin::Classification::Experimentation::ArtificialTask::EvaluationCharacteristics->new($self->getEvaluationCharacteristics());
#  $self->setEvaluationCharacteristics($ev_c);
  
  # Create the model generator and get the list of model kinds
  
  my $modelGenerationCharateristics = $self->getModelGenerationCharacteristics();
  my $modelGenerator = Durin::ModelGeneration::ModelGenerator->create($modelGenerationCharateristics);
  my $modelKinds = $modelGenerator->getModelKinds();
  
  # Initialize the list of tasks
  my $tasks = $self->constructTaskList($modelKinds);
  $self->setTasks($tasks);
}

sub constructTaskList {
  my ($self,$modelKinds) = @_;
  
  my $tasks = [];
  foreach my $modelKind (@$modelKinds) {
    #print Dumper($modelKind);
    my $task = Durin::Classification::Experimentation::ArtificialTask->new(%$self);
    $task->setModelKind($modelKind);
    $task->setResultDir($self->getBaseFileName());
    $task->setName($modelKind->{Name});
    $task->setType("ArtificialTask");
    push @$tasks,$task;
  }
  return $tasks;
}



1;
