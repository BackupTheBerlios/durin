package Durin::Classification::Experimentation::ModelApplier;

use base Durin::Components::Process;

use strict;
use warnings;

sub new_delta
{
    my ($class,$self) = @_;
    
 #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
  my ($class,$self,$source) = @_;
  
  #   $self->setMetadata($source->getMetadata()->clone());
}

#sub create {
#  my ($self,$evaluationCharacteristics) = @_;
  
#  my $name = $self->{METHOD_NAME};
#  my $applier;
#  if ("AUC" eq $name) {
#    $applier = Durin::Classification::Experimentation::AUCModelApplier->new();
#  } 
#}

sub run($)
{
  my ($self) = @_;
  
  my $Input = $self->getInput();
  my $table = $Input->{TABLE};
  my $model = $Input->{MODEL};
  my $class_attno = $table->getMetadata()->getSchema()->getClassPos();
  my $correctClassifications = 0;
  my $incorrectClassifications = 0;
  $table->open();
  $table->applyFunction(sub 
			{
			    my ($row) = @_;
			    
			    my $class = $model->classify($row);
			    if ($class eq $row->[$class_attno])
			    {
				$correctClassifications++;
			    }
			    else
			    {
				$incorrectClassifications++;
			    }
			    # print ".\n";
			}
			);
  $table->close();
  $self->setOutput([$correctClassifications,$incorrectClassifications]);
}

1;
