

package Durin::Classification::Experimentation::LearningCurve;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;
use Time::HiRes;

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
    
    my $input = $self->getInput();
    my $runId = $input->{RUNID};
    my $train = $input->{TRAIN};
    my $test = $input->{TEST};
    my @proportionList = @{$input->{PROPORTIONLIST}};
    my @inducerList = @{$input->{INDUCERLIST}};
    my $resultTable = $input->{RESULTTABLE};
    my $applier = $input->{APPLIER};
    
    #print "Proportion list = ".join(',',@proportionList)."\n";
    my @learningCurve = ();
    
    foreach my $trainProportion (@proportionList)
      { 
	my $newTrain = $train;
	#if ($trainProportion != 1)
	#  {
	    my $splitter = new Durin::PP::Sampling::Sampler->new();
	    {
	      my $input = {};
	      $input->{TABLE} = $train;
	      $input->{PERCENTAGE} = $trainProportion;
	      $splitter->setInput($input);
	    }
	    #print "Sampling proportion: $trainProportion\n";
	    $splitter->run();
	    #print "Done\n";
	    my $output = $splitter->getOutput();
	    $newTrain = $output->{TRAIN};
	#}
	my @sampleResult = ();
	foreach my $inducer (@inducerList)
	  {
	    
	    my $startTime = [Time::HiRes::gettimeofday];
	    {
	      my $input = {};
	      $input->{TABLE} = $newTrain;
	      $inducer->setInput($input);
	    }
	    $inducer->run();
	    my $endLearningTime = [Time::HiRes::gettimeofday];
	    my $learningTime = Time::HiRes::tv_interval($startTime,$endLearningTime);
	    my $model = $inducer->getOutput();
	    print "Run: $runId % Train: ",$trainProportion," Inducer: ",$model->getName(),"\n";
	    print "Learning time: $learningTime\n";
	    # We should provide control over the references.
	    # $inducer->setOutput(undef);
	    {
	      my $input = {};
	      $input->{TABLE} = $test;
	      $input->{MODEL} = $model;
	      $applier->setInput($input);
	    }
	    $applier->run();
	    my $endClassificationTime = [Time::HiRes::gettimeofday];
	    my $classificationTime = Time::HiRes::tv_interval($endLearningTime,$endClassificationTime);
	    print "Classification time: $classificationTime\n";
	    $resultTable->addResult($runId,$trainProportion,$model->getName(),$applier->getOutput());
	  }  
      } 
  }

1;
