

package Durin::Classification::Experimentation::LearningCurve;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

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
	if ($trainProportion != 1)
	  {
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
	  }
	my @sampleResult = ();
	foreach my $inducer (@inducerList)
	  {
	    {
	      my $input = {};
	      $input->{TABLE} = $newTrain;
	      $inducer->setInput($input);
	    }
	    $inducer->run();
	    my $model = $inducer->getOutput();
	    # We should provide control over the references.
	    # $inducer->setOutput(undef);
	    {
	      my $input = {};
	      $input->{TABLE} = $test;
	      $input->{MODEL} = $model;
	      $applier->setInput($input);
	    }
	    print "Run: $runId % Train: ",$trainProportion," Inducer: ",$model->getName(),"\n";
	    $applier->run();
	    $resultTable->addResult($runId,$trainProportion,$model->getName(),$applier->getOutput());
	  }  
      } 
  }

1;
