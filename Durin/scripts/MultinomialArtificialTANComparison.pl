#!/usr/bin/perl -w

use strict;

use Durin::FlexibleIO::System;
use Durin::Classification::System;
use Durin::TAN::RandomTANGenerator;
use Durin::Multinomial::MultinomialModelGenerator;
use Durin::TAN::FrequencyCoherentTANInducer;
use Durin::TAN::FrequencyLaplaceTANInducer;
use Durin::TAN::CoherentLaplaceTANInducer;
use Durin::TAN::CoherentFGGTANInducer;
use Durin::TAN::FGGTANInducer;
use Durin::TAN::CoherentCoherentTANInducer;
use Durin::TBMATAN::SSTBMATANInducer;
use Durin::TBMATAN::TBMATANInducer;
use Durin::ProbClassification::BayesErrorRateCalculator;

my $runs = 5;
my $results = generateModelAndTest($runs);
my $averagesResultList = $results->[0];
my $averageResultHash = calculateAverages($averagesResultList);
printResults($averageResultHash);
printDetailedResults($results->[1]);
print "Number: ".scalar(@{$results->[1]});

sub generateModelAndTest {
  my ($runs) = @_;
 
  my $resultList = [];
  my $totalResultList = [];
  for (my $run = 0 ; $run < $runs ; $run++) {
    print "Started model generation for run $run\n";
    #my $generator = Durin::Multinomial::MultinomialModelGenerator->new();
    my $generator = Durin::TAN::RandomTANGenerator->new();
    $generator->setInput({INDEPENDENCE_PERCENTAGE => 0,
			  NUMBER_OF_ATTRIBUTES_GENERATOR => sub {return 7;}});
    $generator->run();
    my $model = $generator->getOutput()->[0];
    print "Model generated\n";
    
    my $sizes = [10,10,10,10,10]; 
    my $testingSet = $model->getSchema()->generateCompleteDatasetWithoutClass();
    my $runResultList = generateAndTestDatasets($model,$sizes,$testingSet);
    my $runResultAverages = calculateAverages($runResultList);
    push @$totalResultList,@$runResultList;
    push @$resultList,$runResultAverages;
  }
  return [$resultList,$totalResultList];
}

sub printDetailedResults {
  my ($resultList) = @_;
  
  my @classifiers = (keys %{$resultList->[0]});
  my $resultsByClassifier = {};
  foreach my $classifier (@classifiers) {
    $resultsByClassifier->{$classifier} = [];
  }
  foreach my $result (@$resultList) {
    foreach my $classifier (@classifiers) {
      print "A";
      push @{$resultsByClassifier->{$classifier}},$result->{$classifier};
    }
  }
  foreach my $classifier (keys %$resultsByClassifier) {
    print "$classifier: ".join(',',@{$resultsByClassifier->{$classifier}})."\n";
  }
}

sub printResults {
  my ($resultHash) = @_;
  
  foreach my $classifier (keys %$resultHash) {
    print "$classifier average: ".$resultHash->{$classifier}."\n";
  }
}

sub calculateAverages {
  my ($resultList) = @_;
  
  my @classifiers = (keys %{$resultList->[0]});
  my $totals = {};
  foreach my $classifier (@classifiers) {
    $totals->{$classifier} = 0;
  }
  
  foreach my $result (@$resultList) {
    foreach my $classifier (@classifiers) {
      $totals->{$classifier} += $result->{$classifier};
    }
  }
  foreach my $classifier (@classifiers) {
    $totals->{$classifier} /= scalar @$resultList;
  }
  return $totals;
}

sub generateAndTestDatasets {
  my ($model,$sizes,$testingSet) = @_;
  
  my $resultList = [];
  foreach my $size (@$sizes) {
    my $resultHash = generateAndTestDataset($model,$size,$testingSet);
    push @$resultList,$resultHash;
  }
  return $resultList;
}

sub generateAndTestDataset {
  my ($model,$size,$testingSet) = @_;
  
  print "Starting dataset generation\n";

  my $learningSet = $model->generateDataset($size);
  
  print "Dataset generated\n";
  
  print "Started learning\n";
  
  my $inducerList = [Durin::TAN::FrequencyCoherentTANInducer->new(),
		     Durin::TAN::CoherentCoherentTANInducer->new(),
		     Durin::TAN::FGGTANInducer->new(),
		     Durin::TAN::CoherentFGGTANInducer->new(),
		     Durin::TAN::FrequencyLaplaceTANInducer->new(),
		     Durin::TAN::CoherentLaplaceTANInducer->new()#,
		     #Durin::TBMATAN::SSTBMATANInducer->new()
		    ];
  
  my $modelList = learnModels($inducerList,$learningSet);
  print "Finished learning.\n";
  print "Estimating error rates\n";
  
  print "Number of classes: ".$learningSet->getSchema()->getClass()->getType()->getCardinality()."\n";

  my $resultHash = estimateErrorRates($modelList,$testingSet,$model,0);
}

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
    #my $tree = $model->getTree();
    #print $inducer->getName()." tree:\n";
    #print $tree->makestring;
    push @$models,$model
  }
  return $models;
}

sub estimateErrorRates {
  my ($models,$testingSet,$TAN,$randomSample) = @_;
  
  my $resultHash = {};
  my $BayesErrorRateCalculator = Durin::ProbClassification::BayesErrorRateCalculator->new();
  $BayesErrorRateCalculator->setInput({SAMPLE => $testingSet,
				       REAL_MODEL => $TAN,
				       INDUCED_MODEL => $TAN,
				       RANDOM_SAMPLE => $randomSample
				      });
  $BayesErrorRateCalculator->run();
  my $BayesRate = $BayesErrorRateCalculator->getOutput()->{ERROR_RATE};
  print "Estimated Bayes Error Rate for this model is: $BayesRate\n";
  
  foreach my $model (@$models) {
    $BayesErrorRateCalculator->setInput({SAMPLE => $testingSet,
					 REAL_MODEL => $TAN,
					 INDUCED_MODEL => $model,
					 RANDOM_SAMPLE => $randomSample});
    $BayesErrorRateCalculator->run();
    my $estimatedErrorRate = $BayesErrorRateCalculator->getOutput()->{ERROR_RATE};
    print $model->getName()." estimated error rate: $estimatedErrorRate\n";
    $resultHash->{$model->getName()} = $estimatedErrorRate;
  }
  return $resultHash;
}

# End
