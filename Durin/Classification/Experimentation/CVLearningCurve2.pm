package Durin::Classification::Experimentation::CVLearningCurve2;

use Durin::Components::Process;
#use Durin::Data::MemoryTable;
use Durin::Metadata::Table;
use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::LearningCurve;
use Durin::Data::STDFileTable;
use Durin::Classification::ClassedTableSchema;
use POSIX;

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
  #my $inducerList = $input->{INDUCERLIST};
  #my $applier = $input->{APPLIER};
  my $runId = $input->{RUNID};
  print "\n\nStarting run: $runId\n";
 
  my $uniqueId = rand 3003030;
  
  # Create the tables that will hold the different train and test sets.

  my $problems = $self->createTrainAndTestSets($numFolds,$table,$uniqueId);

  # Distribute the observations in the training and test sets.
  $self->distributeObservations($numFolds,$table,$problems);

  for (my $fold = 0; $fold < $numFolds ; $fold++)
    { 
      print "Starting learning curve for fold number $fold\n*******+*****\n";
      $self->learningCurve($input,$runId,$table,$uniqueId,$problems,$fold);
      print "Finished learning curve for fold number $fold\n";
    }
}

sub createTrainAndTestSets {
  my ($self,$numFolds,$table,$uniqueId) = @_;
  
  my $problems = [];
  #my (@countFold);
  for (my $fold = 0; $fold < $numFolds ; $fold++)
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
      #print "Opening $strName\n";
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
      
      push @$problems,([$train,$test]);
   #   @countFold[$fold] = 0;
    }
  return $problems;
}

sub distributeObservations {
  my ($self,$numFolds,$table,$problems) = @_;

  print "Splitting dataset for cross-validation\n";
  my $count = [];
  for (my $fold = 0; $fold < $numFolds ; $fold++)
    {
      $problems->[$fold]->[0]->open(">");
      $problems->[$fold]->[1]->open(">");
      $count->[$fold] = 0;
    }
  
  $table->open();
  
  my $i = 0;
  $table->applyFunction(sub {$i++;});
  print "Number of instances: $i\n";
  my $maxFold = POSIX::ceil($i / $numFolds);
  print "MaxFold = $maxFold\n";
  $table->applyFunction(sub
			{
			  my ($row) = @_;
			  
			  my $luckyFold = int (rand $numFolds);
			  
			  while ($count->[$luckyFold] == $maxFold)
			    {
			      $luckyFold = int (rand $numFolds);
			    }
			  
			  #print "Lucky = $luckyFold\n";
			  for (my $fold = 0; $fold < $numFolds ; $fold++)
			    { 
			      if ($fold == $luckyFold)
				{
				  #print "Adding to test set: $fold\n";
				  $problems->[$fold]->[1]->addRow($row);
				  $count->[$luckyFold]++;
				}
			      else
				{
				  #print "Adding to train set: $fold\n";
				  $problems->[$fold]->[0]->addRow($row);
				}
			    }
			});
  $table->close();
  for (my $fold = 0; $fold < $numFolds ; $fold++)
    { 
      $problems->[$fold]->[0]->close();
      $problems->[$fold]->[1]->close();
    }
  }

sub discretize {
  my ($self,$input,$table,$uniqueId,$fold,$train,$test) = @_;

  print "Starting discretization\n";
  my ($DTrain,$DTest);
  
  my $Discretizer = Durin::PP::Discretization::Discretizer->new();
  my $Din = $input->{DISCINPUT};
  # We create the output table 
  
  $DTrain = Durin::Data::STDFileTable->new();
  my $metadataDTrain = Durin::Metadata::Table->new();
  my $schemaDTrain = Durin::Classification::ClassedTableSchema->new();;
  $metadataDTrain->setSchema($schemaDTrain);
  my $strName = $table->getSchema()->getMetadata()->getInExtInfo()->getDevice()->getFileName();
  #print "strName $strName\n";
  my $csvName = $table->getMetadata()->getInExtInfo()->getDevice()->getFileName();
  my $DTrainName = $csvName."-DTrain-$uniqueId-$fold";
  $metadataDTrain->setName($DTrainName);
  $DTrain->setMetadata($metadataDTrain);
  $DTrain->setExtInfo($strName,$DTrainName.".csv.tmp");
  
  #print "Aqui estoy\n";
  $Din->{TABLE} = $train;
  $Din->{OUTPUT_TABLE} = $DTrain;
  $Discretizer->setInput($Din);
  #print "I am going to discretize\n";
  $Discretizer->run();
  #print "Done\n";
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
  print "Finished discretization\n";
  return ($DTrain,$DTest);	
}

sub learningCurve {
  my ($self,$input,$runId,$table,$uniqueId,$problems,$fold)= @_;

  
  my $train =  $problems->[$fold]->[0];
  my $test = $problems->[$fold]->[1];
  my $LC = Durin::Classification::Experimentation::LearningCurve->new();
  my $LCInput = $input->{LC};

  my $resultTable = $input->{RESULTTABLE};
  my $discretize = $input->{DISCRETIZE};
  my ($DTrain,$DTest);
  if ($discretize) {
    ($DTrain,$DTest) = $self->discretize($input,$table,$fold,$uniqueId,$train,$test);
  } else {
    $DTest = $test;
    $DTrain = $train;
  }
  $LCInput->{RESULTTABLE} = $resultTable;
  $LCInput->{TRAIN} = $DTrain;
  $LCInput->{TEST} = $DTest;
  #print "Continuing run: $runId\n";
  $LCInput->{RUNID} = $runId.".".$fold;
  $LC->setInput($LCInput);
  print "Starting learning curve comparison for fold $fold\n";
  $LC->run();
  print "Finished learning for fold $fold\n";
}

1;
