#
# This object implements the functionality needed to run a list of inducers over a set of Irvine datasets.

package Durin::Classification::Experimentation::IrvineExperiment;

use base Durin::Classification::Experimentation::CompositeExperiment;
use Class::MethodMaker get_set => [-java => qw/ Datasets/];


use Durin::Classification::Experimentation::ResultTable;

use strict;
use warnings;

sub init {
  my ($self,%properties) = @_;
  
  self->SUPER::init(%properties);
  
  my $tasks = constructTaskList();
  $self->setTasks($tasks);
}

sub constructTaskList {
  my ($self) = @_;
  
  my $tasks = [];
  foreach my $dataset_task_info (@{$self->getDatasets()}) {
    my $task = Durin::Classification::Experimentation::IrvineTask->new($self);
    my $special_options;
    if (!($special_options = $dataset_task_info->[1])) {
      $special_options = {};
    }
    setDataset($special_options,$dataset_task_info->[0]);
    $task->add_info($special_options);
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
