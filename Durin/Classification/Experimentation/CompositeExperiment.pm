#
# This object is the base for composite experiments that
# can be run in distributed mode from January 2004 on.

#package Durin::Classification::Experimentation::CompositeExperiment::ExecutionCharacteristics;
#require Durin::Classification::Experimentation::Experiment3;
#push @ISA,'Durin::Classification::Experimentation::Experiment3::ExecutionCharacteristics';
#use Class::MethodMaker
#  new_hash_with_init => 'new',
#  get_set => [-java => qw/ Machines /];

#sub init {};
package Durin::Classification::Experimentation::CompositeExperiment;

use base Durin::Classification::Experimentation::Experiment3;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Tasks /];

use Data::Dumper;
use POSIX;

use strict;
use warnings;
 
sub init {
  my ($self,%properties) = @_;
  #print "AA\n"; 
  #print "Initializing CompositeExperiment\n";
  $self->SUPER::init(%properties);
 
  #my $ex_c = Durin::Classification::Experimentation::CompositeExperiment::ExecutionCharacteristics->new(%{$self->getExecutionCharacteristics()});
#  $self->setExecutionCharacteristics($ex_c);
}

sub run  {
  my ($self) = @_;
  
  # Get the list of machines where the experiment should work
  
  my $machines = $self->getExecutionCharacteristics()->getMachines();
  
  # Get the list of tasks to do 
  
  if (ref $machines eq "ARRAY") {
    my $tasks = $self->getTasks();
    # We are asked to distribute the work into a list of machines
    $self->distributeWork($tasks,$machines);
  } else {
    if ($machines eq "local") {
      # Execute locally
      $self->runLocally();
    } else {
      die "You are giving me a single machine and it is not the local one. Are you sure it is not [myremotemachine]";
    }
  }
}

sub distributeWork {
  my ($self,$tasks,$machines) = @_;
  
  # Distribute experiments in machines
  
  my %controller_pid = ();
  
  foreach my $machine (@$machines) {
    my $task = shift @$tasks;
    my $pid = $self->sendJob($task,$machine);
    $controller_pid{$pid} = $machine;
    if (scalar(@$tasks) == 0) {
      last; # We are finished!
    }
  }
  
  while (scalar(keys %controller_pid) > 0) {
    print "Waiting for a machine to finish its job\n";
    my $pid = wait();
    my $machine = $controller_pid{$pid};
    print "$machine has finished\n";
    delete $controller_pid{$pid};
    if (scalar(@$tasks) > 0) {
      my $new_pid = $self->sendJob(shift @$tasks,$machine);
      $controller_pid{$new_pid} = $machine;
    }
  }
}

sub sendJob {
  my ($self,$task,$machine) = @_;
  
  # Write .exp file
  $task->getExecutionCharacteristics()->setMachines("local");
  my $expFileName = $task->writeExpFile();
  
  # Fork
  my $pid = fork();
  if ($pid == 0) {
    # If you are the son, ask the machine to do the work and wait for it.
    print "\tSending the job\n";
    print "\tTask: ".$task->getName()."\n";
    print "\tMachine to be run at: $machine\n";
    my $traceFileName = $task->getBaseFileName().".trace";
    my $remote_cmd = '"RunExperiment.pl '.$expFileName.">& $traceFileName \"";
    my $cmd = "rsh $machine $remote_cmd";
    #print "Command: $cmd\n";
    system($cmd);
    exit;
  } else { # else return the $pid of the son
    return $pid;
  }
}

sub runLocally {
  my ($self)  = @_;
  
  my $tasks = $self->getTasks();
  
  foreach my $task (@$tasks) {
    $task->run();
  }
}

sub getTasksByInducer {
  my ($self,$inducer) = @_;
  
  my $datasetList = [];
  foreach my $t (@{$self->getTasks()}) {
    my $inducers = $t->getInducers();
    my $isInTask = grep $_ eq $inducer , @$inducers;
    if ($isInTask) {
      #print "And inducer is in it\n";
      push @$datasetList,$t->getName();
    } else {
      #print "Inducer is not in it\n";
    }
  }
  return $datasetList;
}

sub summarize {
  my ($self) = @_;
  
  foreach my $task (@{$self->getTasks()})
    {
      $task->summarize;
    }
}

sub loadSummary {
  my ($self,$AveragesTable) = @_;
  
  
  foreach my $task (@{$self->getTasks()}) {
    $task->loadSummary($AveragesTable); 
  }
 
  return $AveragesTable;
}

# End

1;
