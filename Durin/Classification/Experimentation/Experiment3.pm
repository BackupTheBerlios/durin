#
# This object is the base for ALL experiments from January 2004 on.
#

use strict;
use warnings;

package Durin::Classification::Experimentation::Experiment3::EvaluationCharacteristics;
use Class::MethodMaker 
  new_hash_with_init => 'new',
  get_set => [-java => qw/ Type Runs  Evaluator Folds Proportions DiscIntervals DiscMethod TestingSampleSize LearningSampleSizes/];

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
  get_set => [-java => qw/ LatexTablePrefix SignificanceDir GraphicsDir/];

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
use Matrix::MultiAttribute;
use File::Temp qw/ tempfile/;

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

sub copy_item {
    my ($self,$hash,$key) = @_;

    if (ref($hash->{$key}) eq "ARRAY") {
	print "Copiando lista\n";
	my @list = @{$hash->{$key}};
	$self->{$key} = \@list;
    } else {
	#print "Type: ".ref($self->{$key})."\n";
	$self->{$key} = $hash->{$key};
    }
}


sub add_info {
    my ($self,%hash) = @_;
    foreach my $key (keys %hash) {
	print "key: $key\n";
	if (exists $self->{$key}) {
	    if (UNIVERSAL::isa($self->{$key}, "HASH")){
		if (UNIVERSAL::isa($hash{$key},"HASH")) {
		    add_info($self->{$key},%{$hash{$key}});
		} else{
		    copy_item($self,\%hash,$key);
		}
	    } else {
		copy_item($self,\%hash,$key);
	    }
	} else {
	    copy_item($self,\%hash,$key);
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

sub loadSummary {
  my ($self,$AveragesTable) = @_;
  
  my $fileName = $self->getBaseFileName().".out";
  if (!-e $fileName) {
    print "Task ".$self->getName()." has not yet been calculated\n";
  } else {
    print "Loading $fileName\n";
    $AveragesTable->loadSummary($fileName,$self->getName());
  }
}

sub getFixedCharacteristics {
  my ($self) = @_;

  return [["task",$self->getName()],
	  ["disc_intervals",$self->getEvaluationCharacteristics->getDiscIntervals()],
	  ["disc_method",$self->getEvaluationCharacteristics->getDiscMethod()],
	  ["testing_sample_size",$self->getEvaluationCharacteristics->getTestingSampleSize()]];
}

sub dumpSummaryToSQLite { 
  my ($self,$table) = @_;
  
  # Create new table of averages

  my $AveragesTable = Durin::Classification::Experimentation::ResultTable->new();
  
  # Load summary for this task

  $self->loadSummary($AveragesTable);
  #$AveragesTable->loadValuesAndAverages();
  # Dump info to temporary file
  
  my $tmp_file= new File::Temp(); 
  print "Dumping results to SQLite file ".$tmp_file->filename."\n";
  my $pair_list = $self->getFixedCharacteristics();
  $AveragesTable->dumpToSQLiteFile($tmp_file,$pair_list);
  $tmp_file->close();

  # load the data into the SQLLite table
  $table->load($tmp_file->filename);
}

sub createSQLiteTable {
  my ($self) = @_;
  
  my $table_factory = new Matrix::MultiAttribute::Factory(catfile($self->getBaseFileName(),"sqlite"));
  #my $tester = Durin::Classification::Experimentation::ModelTesterFactory->create($evaluationCharacteristics);
  my $measures = Durin::Classification::Experimentation::ResultTable->getMeasures();
  my $non_measures = [];
  #["task","disc_intervals","disc_method","testing_sample_size"];
  foreach my $field_pair (@{$self->getFixedCharacteristics()}) {
    push @$non_measures,$field_pair->[0];
  }
  push @$non_measures, ("run","fold","proportion","inducer");
  my @field_list = @$non_measures;
  push @field_list, @$measures;
  #foreach my $measure (@$measures) {
  #  push @$field_list,$measure;
  #}
  print "I am going to create the table\n";
  my $table = $table_factory->create($self->getName(),\@field_list);
  print "Creating indexes\n";
  $table->create_index($non_measures);
  
  return $table;
}

sub getSQLiteTable {
  my ($self) = @_;
  
  my $table_factory = new Matrix::MultiAttribute::Factory(catfile($self->getBaseFileName(),"sqlite"));
  #my $tester = Durin::Classification::Experimentation::ModelTesterFactory->create($evaluationCharacteristics);
  my $table = $table_factory->open($self->getName());
  return $table;
}


1;
