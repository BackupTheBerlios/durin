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
use Durin::DFAN::MAPDFANInducer;
use Durin::TBMATAN::SSTBMATANInducer;
use Durin::TBMATAN::TBMATANInducer;
use Durin::ProbClassification::BayesErrorRateCalculator;
use Durin::DFAN::DFAN;
use Durin::TAN::DecomposableLaplaceTANInducer;
use Durin::TAN::DecomposableCoherentTANInducer;

my $csvOutputFile = $ARGV[0];
my $multinomial = $ARGV[1];
my $runs = $ARGV[2];
my $learningSampleSize = $ARGV[3];
my $numAtts = $ARGV[4];
my $numValues = $ARGV[5];
my $indepPercentage = $ARGV[6];

my $results = generateModelAndTest($runs);
my $averagesResultList = $results->[0];
my $averageResultHash = calculateAverages($averagesResultList);
printResults($averageResultHash);
my $outFile = new IO::File();
$outFile->open(">$csvOutputFile");
printDetailedResults($outFile,$results->[1]);
$outFile->close();
print "Number: ".scalar(@{$results->[1]});

sub generateModelAndTest {
  my ($runs) = @_;
 
  my $resultList = [];
  my $totalResultList = [];
  for (my $run = 0 ; $run < $runs ; $run++) {
    print "Started model generation for run $run\n";
    my $generator;
    if ("Multinomial" eq $multinomial) {
	print "Generating samples from a huge multinomial\n";
	$generator = Durin::Multinomial::MultinomialModelGenerator->new();
    } else {
	print "Generating samples from a TAN\n";
	$generator = Durin::TAN::RandomTANGenerator->new();
    }
    $generator->setInput({
			  INDEPENDENCE_PERCENTAGE => $indepPercentage,
			  NUMBER_OF_ATTRIBUTES_GENERATOR => sub {return $numAtts;},
			  NUMBER_OF_VALUES_GENERATOR => sub {return POSIX::ceil(rand ($numValues-1))+1}
		      });
    $generator->run();
    my $model = $generator->getOutput()->[0];
    print "Model generated\n";
    
    my $sizes = [$learningSampleSize]; 
    my $testingSet = $model->getSchema()->generateCompleteDatasetWithoutClass();
    my $runResultList = generateAndTestDatasets($model,$sizes,$testingSet);
    my $runResultAverages = calculateAverages($runResultList);
    push @$totalResultList,@$runResultList;
    push @$resultList,$runResultAverages;
  }
  return [$resultList,$totalResultList];
}

sub printDetailedResults {
  my ($outFile,$resultList) = @_;
  
  my @classifiers = (keys %{$resultList->[0]});
  my $resultsByClassifier = {};
  foreach my $classifier (@classifiers) {
    $resultsByClassifier->{$classifier} = [];
  }
  foreach my $result (@$resultList) {
    foreach my $classifier (@classifiers) {
      push @{$resultsByClassifier->{$classifier}},$result->{$classifier};
    }
  }
  foreach my $classifier (keys %$resultsByClassifier) {
    $outFile->print("$classifier: ".join(',',@{$resultsByClassifier->{$classifier}})."\n");
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
  
  my $inducerList = [Durin::TAN::FrequencyLaplaceTANInducer->new(),
		     #Durin::DFAN::MAPDFANInducer->new(),
		     Durin::TAN::DecomposableLaplaceTANInducer->new(),
		     Durin::TAN::DecomposableCoherentTANInducer->new(),
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
    my $tree = $model->getTree();
    print $inducer->getName()." tree:\n";
    print $tree->makestring;
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
