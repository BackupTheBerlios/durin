# Unimplemented

package Durin::Classification::Experimentation::Bootstrap;

use Durin::Components::Process;
use Durin::Data::MemoryTable;
use Durin::Metadata::Table;

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









sub Iterate
  {
    my ($table,$percent,$numRuns,$methodListRef) = @_;
    
    my ($i,@resultsList);
    @resultsList =();
    for ($i = 1; $i <= $numRuns; $i++)
      {
	my $comparisonTableRef = Compare($table,$percent,$i,$methodListRef);
	
	push @resultList,($comparisonTableRef);
      }
    return \@resultsList;
  }

sub Compare
  {
    my ($table,$percent,$run,$methodListRef) = @_;
    my $splitter = new Durin::PP::Sampling::Sampler->new();
    my ($input) = {};
    $input->{TABLE} = $table;
    $input->{PERCENTAGE} = $percent;
    $splitter->setInput($input);
    $splitter->run();
    my $output = $splitter->getOutput();
    my $train = $output->{TRAIN};
    my $test = $output->{TEST};
    my @runResult = ([$percent,$run]);
    
    foreach my $InductionMethod (@$methodListRef)
      {
	$InductionMethod->setInput($train);
	$InductionMethod->run();
	my $Model = $InductionMethod->getOutput();
	my $applier = Durin::Classification::Experimentation::ModelApplier->new();
	my (%input);
	$input->{TABLE} = $test;
	$input->{MODEL} = $Model;
	$applier->setInput($input);
	$applier->run();
	my $pair = $applier->getOutput();
	print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
	print "Train = $percent Accuracy = ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";
	push @runResult,([$pair->[0],$pair->[1],(100 * $pair->[0])/($pair->[0] + $pair->[1])]);
      }  
    return (\@runResult);
  }








sub run($)
{
  my ($self) = @_;
  
  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my $numFolds = $input->{FOLDS};
  print "CV Folds: $numFolds\n";
  my $inducerList = $input->{INDUCERLIST};
  my $discretize = $input->{DISCRETIZE};
  my $applier = $input->{APPLIER};
  
  # Construct the learning and testing sets.
  
  my (@problems);
  my ($fold);
  for ($fold = 0; $fold < $numFolds ; $fold++)
    { 
      my ($train,$test);
      
      $train = Durin::Data::MemoryTable->new();
      $test = Durin::Data::MemoryTable->new();
      my $metadataTrain = Durin::Metadata::Table->new();
      $metadataTrain->setSchema($table->getMetadata()->getSchema());
      $train->setMetadata($metadataTrain);
      my $metadataTest = Durin::Metadata::Table->new();
      $metadataTest->setSchema($table->getMetadata()->getSchema());
      $test->setMetadata($metadataTest);
      $train->open();
      $test->open();
      push @problems,([$train,$test]);
    }
  $table->open();
  $table->applyFunction(sub
			{
			  my ($row) = @_;
			  
			  my $luckyFold = int (rand $numFolds);
			  #print "Lucky = $luckyFold\n";
			  for ($fold = 0; $fold < $numFolds ; $fold++)
			    { 
			      if ($fold == $luckyFold)
				{
				  #print "Adding to test set: $fold\n";
				  $problems[$fold]->[1]->addRow($row);
				}
			      else
				{
				  #print "Adding to train set: $fold\n";
				  $problems[$fold]->[0]->addRow($row);
				}
			    }
			});
  $table->close();
  for ($fold = 0; $fold < $numFolds ; $fold++)
    { 
      $problems[$fold]->[0]->close();
      $problems[$fold]->[1]->close();
    }
  
  my @CVResult;
  for ($fold = 0; $fold < $numFolds ; $fold++)
    { 
      my $train =  $problems[$fold]->[0];
      my $test = $problems[$fold]->[1];
      my ($DTrain,$DTest);
      if ($discretize)
	{
	  my $Discretizer = Durin::PP::Discretization::Discretizer->new();
	  my $Din = $input->{DISCINPUT};
	  $Din->{TABLE} = $train;
	 
	  $Discretizer->setInput($Din);
	  print "I am going to discretize\n";
	  $Discretizer->run();
	  print "Done\n";
	    my $Dout = $Discretizer->getOutput();
	  $DTrain = $Dout->{TABLE};
	  my $DA = Durin::PP::Discretization::DiscretizationApplier->new();
	  my $DAin;
	  $DAin->{DISC} = $Dout->{DISC};
	  $DAin->{TABLE} = $test;
	  $DA->setInput($DAin);
	  $DA->run();
	  $DTest = $DA->getOutput();
	}
      else
	{
	  $DTest = $test;
	  $DTrain = $train;
	}
      my @foldResult = ();
      foreach my $inducer (@$inducerList)
	{
	  {
	    my $input = {};
	    $input->{TABLE} = $DTrain;
	    $inducer->setInput($input);
	  }
	  $inducer->run();
	  my $Model = $inducer->getOutput();
	  {
	    my $input = {};
	    $input->{TABLE} = $DTest;
	    $input->{MODEL} = $Model;
	    $applier->setInput($input);
	  }
	  $applier->run();
	  #my $pair = $applier->getOutput();
	  #print "Correct: ",$pair->[0]," Incorrect: ",$pair->[1],"\n";
	  #print "Fold: $fold Accuracy = ",(100 * $pair->[0])/($pair->[0] + $pair->[1]), "\n";
#	  push @foldResult,([$pair->[0],$pair->[1]]);	  
	  push @foldResult,($applier->getOutput());
	}  
      push @CVResult,(\@foldResult);
    }
  $self->setOutput(\@CVResult);
}

1;
