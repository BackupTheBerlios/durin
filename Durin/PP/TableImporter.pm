package Durin::PP::TableImporter;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::PP::MetadataConverter;
use Durin::PP::TableTransformator;

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

sub run($)
{
  my ($self) = @_;
  
  my $Input = $self->getInput();

  my $inTable = $Input->{TABLE_SOURCE};
  my $outTable = $Input->{TABLE_DESTINATION};
  my $outputStdFileName = $Input->{STD_FILENAME};
  my $outputStrFileName = $Input->{STR_FILENAME};
  my $outputCSVFileName = $Input->{CSV_FILENAME};
  

  my $tableSchema = $Input->{TABLE_SCHEMA};
  my $class = $Input->{CLASS};
  my $tableName = $Input->{TABLE_NAME};
  
  #print $tableSchema->makestring()."\n";

  my ($newTableMetadata,$transVector) = @{PP::MetadataConverter->STDConversion($tableSchema,$class,$tableName)};
  
  #print $newTableMetadata->makestring()."\n";
  
  $outTable->setMetadata($newTableMetadata);
  $outTable->setExtInfo($outputStrFileName,$outputCSVFileName);

  # Write the std and str files, but first do the addecuate modifications.
  my $outFile = new IO::File;
  $outFile->open(">$outputStdFileName") or die "Unable to open $outputStdFileName\n";
  $outTable->write($outFile);
  $outFile->close();
  
  my $transformer = Durin::PP::TableTransformator->new();
  { 
    my $input = {};
    $input->{TABLE_SOURCE} = $inTable;
    $input->{TABLE_DESTINATION} = $outTable;
    $input->{TRANSFORMATION_VECTOR} = $transVector;
    $transformer->setInput($input);
  }
  $transformer->run();
}

1;
