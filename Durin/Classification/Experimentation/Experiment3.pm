#
# This object is the base for ALL experiments from January 2004 on.
#

use strict;
use warnings;

package Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Runs/];

sub init {
  my ($self,%properties) = @_;
}

package Durin::Classification::Experimentation::Experiment3::ExecutionCharacteristics;
use Class::MethodMaker 
  new_hash_with_init => 'new';

sub init {
  my ($self,%properties) = @_;
}

package Durin::Classification::Experimentation::Experiment3::OutputCharacteristics;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ LatexTablePrefix/];

sub init {
  my ($self,%properties) = @_;
}


package Durin::Classification::Experimentation::Experiment3;

use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Type Name ResultDir DurinDir Inducers EvaluationCharacteristics ExecutionCharacteristics OutputCharacteristics /];

use File::Spec::Functions;
use Data::Dumper;

sub init {
  my ($self,%properties) = @_;

  my $ev_c = Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics->new($self->getEvaluationCharacteristics());
  $self->setEvaluationCharacteristics($ev_c);
  
  my $ex_c = Durin::Classification::Experimentation::Experiment3::ExecutionCharacteristics->new($self->getExecutionCharacteristics());
  $self->setExecutionCharacteristics($ex_c);
  
  my $o_c = Durin::Classification::Experimentation::Experiment3::OutputCharacteristics->new($self->getOutputCharacteristics());
  $self->setOutputCharacteristics($o_c);
}

# Hook method
sub run {};

# Hook method
sub summarize {};

sub getBaseFileName {
  my ($self) = @_;
  
  my $resultDir = $self->getResultDir();
  my $taskName = $self->getName();

  return catfile($resultDir,$taskName);
}

sub add_info {
  my ($self,$hash) = @_;
  foreach my $key (keys %$hash) {
    if (!defined $self->{$key}) {
      $self->{$key} = $hash->{$key};
    } else {
      add_info($self->{$key},$hash->{$key});
    }
  }
}

sub writeExpFile {
  my ($self) = @_;

  my $expFileName = $self->getBaseFileName().".exp";
  print "Writing: $expFileName\n";
  my $file;
  open($file,">$expFileName");
  $file->print(Dumper($self));
  close($file);
  return $expFileName;
}

1;
