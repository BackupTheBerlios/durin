package Durin::Classification::Experimentation::AUCModelApplier;

use Durin::Classification::Experimentation::ModelApplier;

@ISA = (Durin::Classification::Experimentation::ModelApplier);

use strict;

use Durin::Classification::Experimentation::AUCModelApplication;

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

sub run
  {
    my ($self) = @_;
    
    my $Input = $self->getInput();
    my $table = $Input->{TABLE};
    my $model = $Input->{MODEL};
    # We are asked for a Bayesian evaluation. We should be given a model
    my $Bayes = 0;
    my $realModel = undef;
    if (defined $Input->{BAYES}) {
      $Bayes = $Input->{BAYES};
      if (defined $Input->{REAL_MODEL}) {
	$realModel = $Input->{REAL_MODEL}
      } else {
	die "Asked for Bayes evaluation but no model is provided\n";
      }
    }
    my $schema = $table->getMetadata()->getSchema();
    my $class_attno = $schema->getClassPos();
    my $AUCMA = Durin::Classification::Experimentation::AUCModelApplication->new();
    my $classType = $schema->getClass()->getType();
    my $classValues = $classType->getValues();
    $AUCMA->setNumClasses(scalar @$classValues);
    $table->open();
    $table->applyFunction(sub 
			  {
			    my ($row) = @_;
			    
			    my ($distrib,$class) = @{$model->predict($row)};
			    
			    #print "Class Prob:",$distrib->{$class},"\n";
			    #print "Real class:",$realClass,"\n";
			    my $predictedClassIndx = $classType->getValuePosition($class);
			    my $probList = $self->makeListFromHash($classValues,$distrib); 
			    
			    if ($Bayes) {
			      my ($relativeDistrib,$realClass,$absoluteDistrib,$sum) = @{$realModel->predict($row)};
			      my $realClassIndx = $classType->getValuePosition($realClass);
			      my $realProbList = $self->makeListFromHash($classValues,$absoluteDistrib); 
			      $AUCMA->addInstanceBayes($realClassIndx,$realProbList,$sum,$probList,$predictedClassIndx);
			    } else {
			      my $realClass = $row->[$class_attno];
			      my $realClassIndx = $classType->getValuePosition($realClass);
			      $AUCMA->addInstance($realClassIndx,$probList,$predictedClassIndx);
			    }
			  });
    $table->close();
    #my $AUC = $AUCMA->computeAUC();
    #print "AUC = $AUC\n";
    #print "Error rate: ",$PMA->getErrorRate(),", LogP: ",$PMA->getLogP(),"\n";
    $self->setOutput($AUCMA);
  }

sub makeListFromHash {
  my ($self,$classValues,$distrib) = @_;
  my @list = ();
  
  foreach my $val (@$classValues) {
    push @list, $distrib->{$val};
  }
  return \@list;
}

1;
