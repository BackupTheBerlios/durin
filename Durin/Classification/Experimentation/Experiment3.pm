#
# This object is the base for ALL experiments from January 2004 on.
#

use strict;
use warnings;

package Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Runs  Evaluator Folds Proportions DiscIntervals DiscMethod/];

sub init {
  my ($self,%properties) = @_;
}

package Durin::Classification::Experimentation::Experiment3::ExecutionCharacteristics;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ DataDir Machines/];

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
use File::Path;

sub init {
  my ($self,%properties) = @_;

  my $ev_c = Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics->new(%{$self->getEvaluationCharacteristics()});
  $self->setEvaluationCharacteristics($ev_c);
  
  my $ex_c = Durin::Classification::Experimentation::Experiment3::ExecutionCharacteristics->new(%{$self->getExecutionCharacteristics()});
  $self->setExecutionCharacteristics($ex_c);
  
  my $o_c = Durin::Classification::Experimentation::Experiment3::OutputCharacteristics->new(%{$self->getOutputCharacteristics()});
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
  my ($self,%hash) = @_;
  foreach my $key (keys %hash) {
    #print "key: $key\n";
    if (exists $self->{$key}) {
      if (UNIVERSAL::isa($self->{$key}, "HASH")){
#	ref $self->{$key} eq "HASH") {
	#if (ref $hash{$key} eq "HASH") {
	if (UNIVERSAL::isa($hash{$key},"HASH")) {
	  #print "A\n";
	  add_info($self->{$key},%{$hash{$key}});
	} elsif (UNIVERSAL::isa($hash{$key},"ARRAY")){
	  print "Copiando lista\n";
	  my @list = @{$hash{$key}};
	  $self->{$key} = \@list;
	} else {
	  #print "Type: ".ref($self->{$key})."\n";
	  $self->{$key} = $hash{$key};
	}
      } else {
	#print "Type: ".ref($self->{$key})."\n";
	$self->{$key} = $hash{$key};
      }
    } else {
      #print "D\n";
      $self->{$key} = $hash{$key};
    }
  }
}

sub writeExpFile {
  my ($self) = @_;

  my $expFileName = $self->getBaseFileName().".exp.pm";
  print "Writing: $expFileName\n";
  my $file;
  mkpath ($self->getResultDir());
  
  #if (!-e $self->getResultDir()) {
  #   mkdir $self->getResultDir();
  #}
  open($file,">$expFileName");
  $file->print(Dumper($self));
  close($file);
  return $expFileName;
}

1;
