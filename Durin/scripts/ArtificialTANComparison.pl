#!/usr/bin/perl -w

use strict;

use Durin::FlexibleIO::System;
use Durin::Classification::System;
use Durin::TAN::RandomTANGenerator;
use Durin::TAN::FrequencyCoherentTANInducer;
use Durin::TAN::FrequencyLaplaceTANInducer;
use Durin::TAN::CoherentLaplaceTANInducer;
use Durin::TAN::FGGTANInducer;
use Durin::TAN::CoherentCoherentTANInducer;
use Durin::ProbClassification::BayesErrorRateCalculator;

print "Started model generation\n";
my $generator = Durin::TAN::RandomTANGenerator->new();
$generator->setInput({INDEPENDENCE_PERCENTAGE => 0.8,
		      NUMBER_OF_ATTRIBUTES_GENERATOR => sub {return 20;}});
$generator->run();
my $TAN = $generator->getOutput()->[0];
print "Model generated\n";
print "Starting dataset generation\n";

my $dataset = $TAN->generateDataset(50);
my $testingSet = $TAN->generateDataset(200);
print "Datasets generated\n";

print "Started learning\n";

my $inducerList = [Durin::TAN::CoherentCoherentTANInducer->new(),Durin::TAN::FGGTANInducer->new(),Durin::TAN::FrequencyLaplaceTANInducer->new(),Durin::TAN::CoherentLaplaceTANInducer->new()];

my $modelList = learnModels($inducerList,$dataset);

#my $SSTBMATANI = Durin::TBMATAN::SSTBMATANInducer->new();
#$SSTBMATANI->setInput({TABLE => $dataset, COUNTING_TABLE=>$countingTable});
#$SSTBMATANI->run();
#my $SSTBMATAN = $SSTBMATANI->getOutput();
#$tree = $TANFGG->getTree();
#print "TAN FGG tree:\n";
#print $tree->makestring;

print "Finished learning.\n";
print "Estimating error rates\n";

estimateErrorRates($modelList,$testingSet,$TAN);


#$BayesErrorRateCalculator->setInput({SAMPLE => $testingSet,
#				     REAL_MODEL => $TAN,
#				     INDUCED_MODEL => $SSTBMATAN});
#$BayesErrorRateCalculator->run();
#my $SSTBMATANBayesRate = $BayesErrorRateCalculator->getOutput()->{ERROR_RATE};
#print "SSTBMATAN Error rate: $SSTBMATANBayesRate\n";


sub learnModels {
  my ($inducerList,$dataset) = @_;

  my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
  $bc->setInput({TABLE => $dataset,
		 ORDER=> 2});
  $bc->run();
  my $countingTable = $bc->getOutput(); 

  my $models = [];
  foreach my $inducer (@$inducerList) {
    $inducer->setInput({TABLE => $dataset, COUNTING_TABLE => $countingTable});
    $inducer->run();
    my $model = $inducer->getOutput();
    my $tree = $model->getTree();
    print $inducer->getName()." tree:\n";
    print $tree->makestring;
    push @$models,$model
  }
  return $models;
}

sub estimateErrorRates {
  my ($models,$testingSet,$TAN) = @_;
  
  my $BayesErrorRateCalculator = Durin::ProbClassification::BayesErrorRateCalculator->new();
  $BayesErrorRateCalculator->setInput({SAMPLE => $testingSet,
				       REAL_MODEL => $TAN,
				       INDUCED_MODEL => $TAN});
  $BayesErrorRateCalculator->run();
  my $BayesRate = $BayesErrorRateCalculator->getOutput()->{ERROR_RATE};
  print "Estimated Bayes Error Rate for this model is: $BayesRate\n";
  
  foreach my $model (@$models) {
    $BayesErrorRateCalculator->setInput({SAMPLE => $testingSet,
					 REAL_MODEL => $TAN,
					 INDUCED_MODEL => $model});
    $BayesErrorRateCalculator->run();
    my $estimatedErrorRate = $BayesErrorRateCalculator->getOutput()->{ERROR_RATE};
    print $model->getName()." estimated error rate: $estimatedErrorRate\n";
  }
}

# End
