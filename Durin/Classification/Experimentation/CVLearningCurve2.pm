package Durin::Classification::Experimentation::CVLearningCurve2;

use Durin::Components::Process;
#use Durin::Data::MemoryTable;
use Durin::Metadata::Table;
use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::LearningCurve;
use Durin::Data::STDFileTable;
use Durin::Classification::ClassedTableSchema;

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
  my $table = $input->{TABLE};
  my $numFolds = $input->{FOLDS};
  # print "CV Folds: $numFolds\n";
  my $LCInput = $input->{LC};
  #my $inducerList = $input->{INDUCERLIST};
  my $discretize = $input->{DISCRETIZE};
  #my $applier = $input->{APPLIER};
  my $resultTable = $input->{RESULTTABLE};
  my $runId = $input->{RUNID};
  print "Starting run: $runId\n";
  $LCInput->{RESULTTABLE} = $resultTable;
  
  # Construct the learning and testing sets.
  
  my (@problems);
  my ($fold);
  #my (@countFold);
  my $uniqueId = rand 3003030;
  for ($fold = 0; $fold < $numFolds ; $fold++)
    { 
      my ($train,$test);
      
      # Here we create them in memory. 

      #$train = Durin::Data::MemoryTable->new();
      #$test = Durin::Data::MemoryTable->new();
      #my $metadataTrain = Durin::Metadata::Table->new();
      #$metadataTrain->setSchema($table->getMetadata()->getSchema());
      #$metadataTrain->setName($table->getMetadata()->getName()."-Train");
      #$train->setMetadata($metadataTrain);
      #my $metadataTest = Durin::Metadata::Table->new();
      #$metadataTest->setSchema($table->getMetadata()->getSchema());
      #$metadataTest->setName($table->getMetadata()->getName()."-Test");
      #$test->setMetadata($metadataTest);
      
      # Now I will create them on disk

      
      $train = Durin::Data::STDFileTable->new();
      my $metadataTrain = Durin::Metadata::Table->new();
      my $schemaTrain = $table->getMetadata()->getSchema()->clone();
      $metadataTrain->setSchema($schemaTrain);
      #my $trainName = $table->getMetadata()->getName()."-Train-$uniqueId-$fold";
      # we need to have the .str file name. This is not well made. We should create the str, but...
      
      my $strName = $table->getSchema()->getMetadata()->getInExtInfo()->getDevice()->getFileName();
      print "Opening $strName\n";
      my $csvName = $table->getMetadata()->getInExtInfo()->getDevice()->getFileName();
      my $trainName = $csvName."-Train-$uniqueId-$fold";

      $metadataTrain->setName($trainName);
      $train->setMetadata($metadataTrain);
      $train->setExtInfo($strName,$trainName.".csv.tmp");

      $test = Durin::Data::STDFileTable->new();
      my $metadataTest = Durin::Metadata::Table->new();
      my $schemaTest = $table->getMetadata()->getSchema()->clone();
      $metadataTest->setSchema($schemaTest);
      my $testName = $csvName."-Test-$uniqueId-$fold";
      $metadataTest->setName($testName);
      $test->setMetadata($metadataTest);
      $test->setExtInfo($strName,$testName.".csv.tmp");
      
      $train->open(">");
      $test->open(">");
      push @problems,([$train,$test]);
   #   @countFold[$fold] = 0;
    }
  print "Aun no pase\n";
    $table->open();
  print "Pase\n";
  $table->applyFunction(sub
			{
			  my ($row) = @_;
			  
			  my $luckyFold = int (rand $numFolds);

	#		  while ($count[$luckyFold] == $maxFold)
	#		    {
	#		      $luckyFold = int (rand $numFolds);
	#		    }
			  
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
  
  my $LC = Durin::Classification::Experimentation::LearningCurve->new();
  for ($fold = 0; $fold < $numFolds ; $fold++)
    { 
      my $train =  $problems[$fold]->[0];
      my $test = $problems[$fold]->[1];
      my ($DTrain,$DTest);
      if ($discretize)
	{
	  my $Discretizer = Durin::PP::Discretization::Discretizer->new();
	  my $Din = $input->{DISCINPUT};
	  # We create the output table 

	  $DTrain = Durin::Data::STDFileTable->new();
	  my $metadataDTrain = Durin::Metadata::Table->new();
	  my $schemaDTrain = Durin::Classification::ClassedTableSchema->new();;
	  $metadataDTrain->setSchema($schemaDTrain);

	  my $strName = $table->getSchema()->getMetadata()->getInExtInfo()->getDevice()->getFileName();
	  print "strName $strName\n";
	  my $csvName = $table->getMetadata()->getInExtInfo()->getDevice()->getFileName();
	  my $DTrainName = $csvName."-DTrain-$uniqueId-$fold";
	  $metadataDTrain->setName($DTrainName);
	  $DTrain->setMetadata($metadataDTrain);
	  $DTrain->setExtInfo($strName,$DTrainName.".csv.tmp");
	  
	  print "Aqui estoy\n";
	  $Din->{TABLE} = $train;
	  $Din->{OUTPUT_TABLE} = $DTrain;
	  $Discretizer->setInput($Din);
	  print "I am going to discretize\n";
	  $Discretizer->run();
	  print "Done\n";
	  my $Dout = $Discretizer->getOutput();
	  #$DTrain = $Dout->{TABLE};

	  $DTest = Durin::Data::STDFileTable->new();
	  my $metadataDTest = Durin::Metadata::Table->new();
	  my $schemaDTest = Durin::Classification::ClassedTableSchema->new();
	  $metadataDTest->setSchema($schemaDTest);
	  my $DTestName = $csvName."-DTest-$uniqueId-$fold";
	  $metadataDTest->setName($DTestName);
	  $DTest->setMetadata($metadataDTest);
	  $DTest->setExtInfo($strName,$DTestName.".csv.tmp");
	  
	  my $DA = Durin::PP::Discretization::DiscretizationApplier->new();
	  my $DAin;
	  $DAin->{DISC} = $Dout->{DISC};
	  $DAin->{TABLE} = $test;
	  $DAin->{OUTPUT_TABLE} = $DTest;
	  $DA->setInput($DAin);
	  $DA->run();
	  #$DTest = $DA->getOutput();
	}
      else
	{
	  $DTest = $test;
	  $DTrain = $train;
	}
      $LCInput->{TRAIN} = $DTrain;
      $LCInput->{TEST} = $DTest;
      print "Continuing run: $runId\n";
      $LCInput->{RUNID} = $runId.".".$fold;
      $LC->setInput($LCInput);
      $LC->run();
    }
}

1;
