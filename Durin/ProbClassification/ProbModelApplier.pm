package Durin::ProbClassification::ProbModelApplier;

use Durin::Classification::Experimentation::ModelApplier;

@ISA = (Durin::Classification::Experimentation::ModelApplier);

use strict;

use Durin::ProbClassification::ProbModelApplication;

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
    my $class_attno = $table->getMetadata()->getSchema()->getClassPos();
    my $PMA = Durin::ProbClassification::ProbModelApplication->new();
    $table->open();
    $table->applyFunction(sub 
			  {
			    my ($row) = @_;
			    
			    my $realClass = $row->[$class_attno];
			    my ($distrib,$class) = @{$model->predict($row)};
			    
			    #print "Class Prob:",$distrib->{$class},"\n";
			    #print "Real class:",$realClass,"\n";
			    $PMA->addPClass($distrib->{$realClass});
			    if ($realClass eq $class)
			      {
				$PMA->increaseOKs();
			      }
			    else
			      {
				$PMA->increaseWrongs();
			      }
			    
			    # print ".\n";
			  }
			 );
    $table->close();
    print "Error rate: ",$PMA->getErrorRate(),", LogP: ",$PMA->getLogP(),"\n";
    $self->setOutput($PMA);
  }

1;
