#
# This object implements the functionality needed to run a list of inducers over a set of Irvine datasets.

package Durin::Classification::Experimentation::IrvineExperiment;

use base Durin::Classification::Experimentation::CompositeExperiment;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Datasets/];

use Durin::Classification::Experimentation::IrvineTask;
use Durin::Classification::Experimentation::ResultTable;

use strict;
use warnings;

sub init {
  my ($self,%properties) = @_;
  
  #print "Initializing Irvine Experiment\n";
  $self->SUPER::init(%properties);
  #my $ev_c = Durin::Classification::Experimentation::IrvineTask::EvaluationCharacteristics->new($self->getEvaluationCharacteristics());
#  $self->setEvaluationCharacteristics($ev_c);
  
#  my $ex_c = Durin::Classification::Experimentation::IrvineTask::ExecutionCharacteristics->new($self->getExecutionCharacteristics());
#  $self->setExecutionCharacteristics($ex_c);
#  print "B\n";
  my $tasks = $self->constructTaskList();
  $self->setTasks($tasks);
}

sub constructTaskList {
  my ($self) = @_;
  
  my $tasks = [];
  foreach my $dataset_task_info (@{$self->getDatasets()}) {
    my $task = Durin::Classification::Experimentation::IrvineTask->new(%$self);
    #print "Task initialized\n";
    my $special_options;
    if (!($special_options = $dataset_task_info->[1])) {
      $special_options = {};
    }
    $task->add_info(%$special_options);
    $task->setResultDir($self->getBaseFileName());
    $task->setDataset($dataset_task_info->[0]);
    $task->setName($dataset_task_info->[0]);
    $task->setType("IrvineTask");
    push @$tasks,$task;
  }
  return $tasks;
}

#sub run
#{
#  my ($self) = @_;
#  
#  foreach my $task (@{$self->getTasks()})
#    {
#      $task->run();
#    }
#}

1;
