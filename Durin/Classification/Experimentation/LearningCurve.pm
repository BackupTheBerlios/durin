

package Durin::Classification::Experimentation::LearningCurve;

use strict;
use warnings;

use Durin::Components::Process;

@Durin::Classification::Experimentation::LearningCurve::ISA = qw(Durin::Components::Process);

use Time::HiRes;

sub new_delta {
  my ($class,$self) = @_;
}

sub clone_delta {
  my ($class,$self,$source) = @_;
}

sub run {
  my ($self) = @_;
  
  my $input = $self->getInput();
  my $runId = $input->{RUNID};
  my $train = $input->{TRAIN};
  my $test = $input->{TEST};
  my @proportionList = @{$input->{PROPORTIONLIST}};
  my $compositeInducer = $input->{COMPOSITE_INDUCER};
  my $resultTable = $input->{RESULTTABLE};
  my $applier = $input->{APPLIER};
  my $shareCountTable = $input->{SHARE_COUNT_TABLE};

  #print "Proportion list = ".join(',',@proportionList)."\n";
  my @learningCurve = ();
  foreach my $trainProportion (@proportionList) {
    $self->performComparison($train, $test, $runId, $compositeInducer, $applier, $resultTable, $trainProportion,$shareCountTable);
  }
}

sub performComparison {
  my ($self, $train, $test, $runId, $compositeInducer, $applier, $resultTable, $trainProportion,$shareCountTable) = @_;
  
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
  #my @sampleResult = ();
  
  my $modelList = $self->learnModels($newTrain, $runId, $trainProportion,$compositeInducer,$shareCountTable);
  
  foreach my $model (@$modelList) {
    print "Started testing with model ".$model->getName()."\n";
    $self->performTesting($test, $runId, $trainProportion, $applier,$model,$resultTable);
    print "****************\n";
  }
}

sub learnModels($$$$$) {
  my ($self, $train, $runId, $trainProportion,$compositeInducer,$shareCountTable) = @_;

  my $startTime;
  my $previous = sub { 
    my ($inducer) = @_;
    print "Started learning with inducer ".$inducer->getName()."\n";
    $startTime = [Time::HiRes::gettimeofday];
  };
  my $posterior = sub {
    my ($inducer) = @_;
    my $endTime = [Time::HiRes::gettimeofday];
    my $learningTime = Time::HiRes::tv_interval($startTime,$self->{END_LEARNING_TIME});   
    my $model = $inducer->getOutput();
    print "Run: $runId % Train: ",$trainProportion," Inducer: ",$model->getName(),"\n";
    print "Learning time: $learningTime\n";
  };
  $compositeInducer->setPreviousToLearningHook($previous);
  $compositeInducer->setPosteriorToLearningHook($posterior);
  {
    my $input = {};
    $input->{TABLE} = $train;
    $input->{SHARE_COUNT_TABLE} = $shareCountTable;
    $compositeInducer->setInput($input);
  }
  $compositeInducer->run();
  return $compositeInducer->getOutput()->{MODEL_LIST};
}
		
		#sub performLearning {
		#  my ($self, $train, $runId, $trainProportion,$inducer) = @_;
		#  my $startTime = [Time::HiRes::gettimeofday];
		#  {
		#    my $input = {};
		#    $input->{TABLE} = $train;
		#    $inducer->setInput($input);
		#  }
		#  $inducer->run();
		#  $self->{END_LEARNING_TIME} = [Time::HiRes::gettimeofday];
		#  my $learningTime = Time::HiRes::tv_interval($startTime,$self->{END_LEARNING_TIME});
		#  my $model = $inducer->getOutput();
		#  print "Run: $runId % Train: ",$trainProportion," Inducer: ",$model->getName(),"\n";
		#  print "Learning time: $learningTime\n";
		#  # We should provide control over the references.
		#  # $inducer->setOutput(undef);
		#  return $model;
		#}

		
sub performTesting {
  my ($self, $test, $runId, $trainProportion, $applier, $model, $resultTable) = @_;

  my $startTime = [Time::HiRes::gettimeofday];
  {
    my $input = {};
    $input->{TABLE} = $test;
    $input->{MODEL} = $model;
    $applier->setInput($input);
  }
  $applier->run();
  $resultTable->addResult($runId,$trainProportion,$model->getName(),$applier->getOutput());
  my $endClassificationTime = [Time::HiRes::gettimeofday];
  my $classificationTime = Time::HiRes::tv_interval($startTime,$endClassificationTime);
  print "Classification time: $classificationTime\n";
}

1;
