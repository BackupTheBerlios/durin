#!/home/cerquide/software/perl/bin/perl -w 
# Learns a TAN and writes it in Netica format

use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;
use Durin::TAN::CoherentCoherentTANInducer;
use Durin::TAN::FGGTANInducer;
use Durin::Classification::Experimentation::ModelApplier;
use Durin::PP::Discretization::Discretizer;
use Durin::Data::STDFileTable;

if ($#ARGV != 0)
  {
    die "\nUsage: ShowSimpleRules.pl in.std\n\n";
  }

my $file_name = $ARGV[0];
#my $outFileName = $ARGV[1];
my $file = new IO::File;
$file->open("<$file_name") or die "Unable to open $file_name\n";
my $table = Durin::Data::FileTable->read($file);
$file->close();

# print "Starting Bayesian Network learning.\n";


my $schema = $table->getMetadata()->getSchema();
my $classPos = $schema->getClassPos();

my ($DTrain);
if ($schema->hasNumericAttributes()) { 
  my $Discretizer = Durin::PP::Discretization::Discretizer->new();
  my $Din;
  $Din->{DISCMETHOD} = "Frequency";
  $Din->{NUMINTERVALS} = 5;
  # We create the output table 
  
  $DTrain = Durin::Data::STDFileTable->new();
  my $metadataDTrain = Durin::Metadata::Table->new();
  my $schemaDTrain = Durin::Classification::ClassedTableSchema->new();;
  $metadataDTrain->setSchema($schemaDTrain);
  my $strName = $table->getSchema()->getMetadata()->getInExtInfo()->getDevice()->getFileName();
  #print "strName $strName\n";
  my $csvName = $table->getMetadata()->getInExtInfo()->getDevice()->getFileName();
  my $DTrainName = $csvName."-DTrain-dsctmp";
  $metadataDTrain->setName($DTrainName);
  $DTrain->setMetadata($metadataDTrain);
  $DTrain->setExtInfo($strName,$DTrainName.".csv.tmp");
  
  #print "Aqui estoy\n";
  $Din->{TABLE} = $table;
  $Din->{OUTPUT_TABLE} = $DTrain;
  $Discretizer->setInput($Din);
  #print "I am going to discretize\n";
  $Discretizer->run();
  #print "Done\n";
  my $Dout = $Discretizer->getOutput();
  #$DTrain = $Dout->{TABLE};
} else {
  $DTrain = $table;
}

my $bc = Durin::ProbClassification::ProbApprox::Counter->new();
{
  my $input = {};
  $input->{TABLE} = $DTrain;
  $input->{ORDER} = 1;
  $bc->setInput($input);
}
$bc->run();
my $ct = $bc->getOutput();

# Recorremos la tabla calculando el porcentaje de simple rules.

$schema = $DTrain->getMetadata()->getSchema();
my $possibleSimpleRules = 0;
my $realSimpleRules = 0;
my $classAtt = $schema->getAttributeByPos($classPos);
my @classValues = @{$classAtt->getType()->getValues()};
foreach my $classVal (@classValues) {
  for ($node = 0 ; $node < $schema->getNumAttributes() ; $node++) {
    if ($node != $classPos) {
      my $nodeType = $schema->getAttributeByPos($node)->getType();
      #if ($nodeType->getName() eq "Categorical") {
      my @nodeValues = @{$nodeType->getValues()};
	foreach my $nodeVal (@nodeValues) {
	  if ($ct->getCountXClass($classVal,$node,$nodeVal) == 0) {
	    $realSimpleRules++;
	  }
	  $possibleSimpleRules++;
	}
      #}
    }
  }
}
my $pct = $realSimpleRules/$possibleSimpleRules;
print "SR = $realSimpleRules, PSR = $possibleSimpleRules, \%SR=  $pct\n";
print "Done\n";
