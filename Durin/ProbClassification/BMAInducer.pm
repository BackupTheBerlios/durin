package Durin::ProbClassification::BMAInducer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::ProbClassification::ProbModelEvaluator;
use Durin::ProbClassification::BMA;

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

sub run($)
{
  my ($self) = @_;
  
  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $modelList = $input->{MODELLIST};
  my $PME = Durin::ProbClassification::ProbModelEvaluator->new();
  {
    my ($Input);
    $Input->{TABLE} = $table;
    $Input->{MODELLIST} = $modelList;
    $PME->setInput($Input);
  }
  $PME->run();
  my $weightsRef = $PME->getOutput();
  my $BMA = Durin::ProbClassification::BMA->new();
  foreach my $model (@$modelList)
    {
      print $weightsRef->{$model},",";
      $BMA->addWeightedModel($model,$weightsRef->{$model});
    }
  print "\n";
  $BMA->normalizeWeights();
  $BMA->setSchema($table->getMetadata()->getSchema());
  $self->setOutput($BMA);
}

1;
