#!/home/cerquide/software/perl/bin/perl -w
# Calculates the comparison between different learning methods 
# usage: 
# IndComp.pl <script_file>

# Systems

use Durin::FlexibleIO::System;
use Durin::Classification::System;

# Modules

use Durin::Classification::Experimentation::ModelApplier;
use Durin::PP::Sampling::Sampler;
use Durin::PP::Discretization::Discretizer;
use Durin::PP::Discretization::DiscretizationApplier;
use Durin::Classification::Experimentation::CVLearningCurve2;
use Durin::Utilities::MathUtilities;
use Durin::ProbClassification::ProbModelApplier;
use Durin::Classification::Experimentation::ResultTable;

# Perl modules

use IO::File;

$| = 1;

# Default characteristics (this can also be made a file and put it somewhere...)

my $inFileName = "";
my $numFolds = 10;
my $numSplits = 1;
my $numRepeats = 1;
my $outFileName = "";
my $percentage = 1;
my $discOptions = {};
$discOptions->{DISCMETHOD} = "Fayyad-Irani";
my $inducerNamesList = ["NB","TAN+MS"];
my $inducerOptions = {};
$inducerOptions->{"NB"} = {};
$inducerOptions->{"TAN+MS"} = {};
my $totalsOutFileName = "";
my @proportionList = ();

# The concrete characteristics of the experiment are stored into the input file.

my $InputFile = $ARGV[0];
eval `cat $InputFile`;

$file = new IO::File;
$file->open("<$inFileName") or die "Unable to open input file: $inFileName\n";

my $table_total = Durin::Data::FileTable->read($file);
$file->close();

printExperimentalConditions($percentage,$table_total,$numRepeats,$numFolds,$discOptions,$proportionList,$inducerNamesList);

if (scalar (@proportionList) == 0)
  {
    print "Initializing proportions\n";
    for ($i=1; $i <= $numSplits; $i++)
      { 
	push @proportionList,($i/$numSplits);
      }
  }

my $resultTable = Durin::Classification::Experimentation::ResultTable->new();
my $CVLC2 = Durin::Classification::Experimentation::CVLearningCurve2->new();

my $thisRepetition;
for ($thisRepetition = 0; $thisRepetition < $numRepeats ; $thisRepetition++)
  {
    doRun($thisRepetition,$percentage,$table_total,$numFolds,$resultTable,$discOptions,$proportionList,$inducerNamesList);
  }

# Write the output file

$file = new IO::File;
$file->open(">$outFileName") or die "Unable to open $outFileName\n";

# write  the headers (the field names) and initialize averages table.

my $AveragesTable;
print $file "Fold,Proportion";
my $modelList = $resultTable->getModels();
my $proportionList = $resultTable->getProportions();
foreach $model (@$modelList)
  {
    print $file (",OK".$model,",WR".$model,",ER".$model,",LP".$model);
    foreach my $proportion (@$proportionList)
      {
	$AveragesTable->{$model}->{$proportion}->{OKS} = 0;
	$AveragesTable->{$model}->{$proportion}->{WRONGS} = 0;
	$AveragesTable->{$model}->{$proportion}->{ERRORRATE} = 0;
	$AveragesTable->{$model}->{$proportion}->{LOGP} = 0;	
	$AveragesTable->{$model}->{$proportion}->{OKSLIST} = ();
	$AveragesTable->{$model}->{$proportion}->{WRONGSLIST} = ();
	$AveragesTable->{$model}->{$proportion}->{ERRORRATELIST} = ();
	$AveragesTable->{$model}->{$proportion}->{LOGPLIST} = ();
	$AveragesTable->{$model}->{$proportion}->{N} = 0;
      }
  }
print $file "\n";

# write the contents

foreach my $propResult (@{$resultTable->getResultsByModel()})
  {
    my $fold = $propResult->[0];
    my $proportion = $propResult->[1];	
    print $file ($fold,",",$proportion);
    my $PMAList = $propResult->[2];
    foreach $PMAPair (@$PMAList)
      {
	my $model = $PMAPair->[0];
	my $PMA = $PMAPair->[1];
	print $file (",",$PMA->getNumOKs(),",",$PMA->getNumWrongs(),",",$PMA->getErrorRate(),",",$PMA->getLogP());
	
	$AveragesTable->{$model}->{$proportion}->{OKS} += $PMA->getNumOKs();
	$AveragesTable->{$model}->{$proportion}->{WRONGS} += $PMA->getNumWrongs();	
	$AveragesTable->{$model}->{$proportion}->{ERRORRATE} += $PMA->getErrorRate();	
	$AveragesTable->{$model}->{$proportion}->{LOGP} += $PMA->getLogP();	
	$AveragesTable->{$model}->{$proportion}->{N} += 1;
	
	push @{$AveragesTable->{$model}->{$proportion}->{OKSLIST}},($PMA->getNumOKs());
	push @{$AveragesTable->{$model}->{$proportion}->{WRONGSLIST}},($PMA->getNumWrongs());	
	push @{$AveragesTable->{$model}->{$proportion}->{ERRORRATELIST}},($PMA->getErrorRate());	
	push @{$AveragesTable->{$model}->{$proportion}->{LOGPLIST}},($PMA->getLogP());	
	#print ($AveragesTable->{$model}->{$proportion}->{N},"\n");
	#print ($model,",",$proportion,"\n");
      }
    print $file "\n";
  }
$file->close();

# Write the totals output file

$file = new IO::File;
$file->open(">$totalsOutFileName") or die "Unable to open $totalsOutFileName\n";


print "AVERAGES\n";
print "--------\n";
print $file "AVERAGES\n";
print $file "--------\n";


foreach my $proportion (@$proportionList)
  {
#    print $file ("AVERAGE,",$proportion);
    print $file "Proportion: $proportion\n";
    print "Proportion: $proportion\n";
    foreach my $model (@$modelList)
      {
	my $AT = $AveragesTable->{$model}->{$proportion};
	my %StDev;
	#print "N = ",$AT->{N};
	$AT->{OKS} = $AT->{OKS} / $AT->{N};
	#print "OKLIST:",join(",",@{$AT->{OKSLIST}}),"\n";

	$StDev{OKS} = Durin::Utilities::MathUtilities::StDev($AT->{OKS},$AT->{OKSLIST});
	$AT->{WRONGS} = $AT->{WRONGS} / $AT->{N};
	#print "WRONGSLIST:",join(",",@{$AT->{WRONGSLIST}}),"\n";

	$StDev{WRONGS} = Durin::Utilities::MathUtilities::StDev($AT->{WRONGS},$AT->{WRONGSLIST});
	$AT->{ERRORRATE} = $AT->{ERRORRATE} / $AT->{N};
	#print "ERRORRATELIST:",join(",",@{$AT->{ERRORRATELIST}}),"\n";

	$StDev{ERRORRATE} = Durin::Utilities::MathUtilities::StDev($AT->{ERRORRATE},$AT->{ERRORRATELIST});
	#print "LOGPLIST:",join(",",@{$AT->{LOGPLIST}}),"\n";

	$AT->{LOGP} = $AT->{LOGP} / $AT->{N};
	$StDev{LOGP} = Durin::Utilities::MathUtilities::StDev($AT->{LOGP},$AT->{LOGPLIST});
	print $file ($model,":[OKS:",$AT->{OKS},"+-",$StDev{OKS},"],[WRONGS:",$AT->{WRONGS},"+-",$StDev{WRONGS},"],[ERRORRATE:",$AT->{ERRORRATE},"+-",$StDev{ERRORRATE},"],[LOGP:",$AT->{LOGP},"+-",$StDev{LOGP},"]\n");
	print ($model,":[OKS:",$AT->{OKS},"+-",$StDev{OKS},"],[WRONGS:",$AT->{WRONGS},"+-",$StDev{WRONGS},"],[ERRORRATE:",$AT->{ERRORRATE},"+-",$StDev{ERRORRATE},"],[LOGP:",$AT->{LOGP},"+-",$StDev{LOGP},"]\n");
	
      }
   # print $file "\n";
  }

$file->close();

sub doRun {
  my ($thisRepetition,$percentage,$table_total,$numFolds,$resultTable,$discOptions,$proportionList,$inducerNamesList) = @_;
  
  my $table;
  $table = $table_total;
  
  if ($percentage!=1)
    {
      my $splitter = new Durin::PP::Sampling::Sampler->new();
      my ($input) = {};
      $input->{TABLE} = $table_total;
      $input->{PERCENTAGE} = $percentage;
      $splitter->setInput($input);
      $splitter->run();
      my $output = $splitter->getOutput();
      $table = $output->{TRAIN};
    }
  my $input;
    $input->{TABLE} = $table;
    $input->{FOLDS} = $numFolds;
    $input->{RESULTTABLE} = $resultTable;
    $input->{DISCRETIZE} = $table->getMetadata()->getSchema()->hasNumericAttributes();
    $input->{RUNID} = $thisRepetition;
    if ($input->{DISCRETIZE})
      {
	$input->{DISCINPUT} = $discOptions;
      }
    my $LCInput;
    $LCInput->{PROPORTIONLIST} = \@proportionList;

    my $inducerList = [];
    foreach my $inducerName (@$inducerNamesList)
      {
	push @$inducerList,Durin::Classification::Registry->getInducer($inducerName);
      }
    $LCInput->{INDUCERLIST} = $inducerList;
    $LCInput->{APPLIER} = Durin::ProbClassification::ProbModelApplier->new();
    $input->{LC} = $LCInput;
    $CVLC2->setInput($input);
    $CVLC2->run();
  }


sub printExperimentalConditions {
  my ($percentage,$table_total,$numRepeats,$numFolds,$discOptions,$proportionList,$inducerNamesList) = @_;
  
  print "\nRunning inducer comparison using cross validation with learning curve\n";
  print "-------------------------------------------\n";
  print "Dataset: ".$table_total->getName()."\n";
  print "Inducers compared: ",join(",",@$inducerNamesList)."\n";
  if ($percentage==1) {
    print "Applying no sampling prior to cross validation\n";
  } else {
    print "Applying a sampling of ".($percentage*100)."% prior to cross validation";
  }
  print "Number of cross validation runs: $numRepeats\n";
  print "Number of cross validation folds: $numFolds\n";
  print "List of proportions for learning curve: ",join(",",@proportionList)."\n";
  if (defined $discOptions->{DISCMETHOD}) {
    print "Discretization method: ".$discOptions->{DISCMETHOD}."\n";
    if (defined $discOptions->{NUMINTERVALS}) {
      print "Number of intervals: ".$discOptions->{NUMINTERVALS}."\n";
    }
  }
  print "Input file name: $inFileName\n";
  print "Output file name: $outFileName\n";
  print "Totals output file name: $totalsOutFileName\n";
  my $schema_string = $table_total->getMetadata()->makestring();
  print "Dataset structure: $schema_string\n";
  print "--------------------------------------\n";
}
