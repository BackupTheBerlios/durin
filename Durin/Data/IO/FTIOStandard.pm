package Durin::Data::IO::FTIOStandard;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "Data::FileTable";
$IO_FORMAT = "Standard";

use strict;

use Durin::Data::FileTable;
use Durin::FlexibleIO::ExtInfo;
use Durin::Metadata::Table;
use Durin::Utilities::StringUtilities;

sub write
  {
    my ($class,$disp,$table) = @_;

    
    $disp->print("Format: Durin::Data::FTIOStandard\n");
   
    my $metadata = $table->getMetadata();
   
    $disp->print($metadata->getName(),"\n");
    
    my $schema = $metadata->getSchema();
    
    my $schemaExtInfo = $schema->getMetadata()->getOutExtInfo(); 
   
    $disp->print($schemaExtInfo->makestring(),"\n");
    my $dataOutExtInfo = $metadata->getOutExtInfo();
    my $dataInExtInfo = $metadata->getInExtInfo();
    $disp->print($dataOutExtInfo->makestring(),"\n");
    
    # Now we write the schema into its corresponding file
    
    $schemaExtInfo->write($schema);

    # Here we have to write the file when in and out extinfo are different.
    #if ($dataInExtInfo->getDevice()->getNa
    
    
    #$outFile = Durin::Data::CSV::UnixCSVColumnedData->new();
    #$outFile->setOutFileName($outputCSVFileName);
    #$outFile->open(">");
    #$inFile->open("<");
    #my $first = 0;
    #$inFile->applyFunction(sub
	#	       {
	#		 my ($row) = @_;
	#	
	#		 if ($first)
	#		   {
	#		     $outFile->addRow($row);
	#		   }
	#		 else
	#		   {
	#		     $first = 1;
	#		   }
	#	       });
    #$inFile->close();
    #$outFile->close();
    
    #$schemaExtInfo->open(">");
    #$schemaExtInfo->write($schema);
    #$schemaExtInfo->close();
  }

sub read
  {
    my ($class,$disp) = @_;

    if ($disp->getline() ne "Format: Durin::Data::FTIOStandard\n")
    {
	die "Data::FTIOStandard Incorrect format\n";
    }
    my $name = Durin::Utilities::StringUtilities::removeEnter($disp->getline());

    #print "Name: $name\n";

    my $metadata = Durin::Metadata::Table->new();
    $metadata->setName($name);

    # Load the metadata of the TableSchema
    
    my $schemaExtInfoStr = $disp->getline();
    $schemaExtInfoStr =~ /^(.*)\n$/;
    $schemaExtInfoStr = $1;
    my $schemaExtInfo1 = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
    my $schemaExtInfo2 = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
    
    my $schema_metadata = Durin::Components::Metadata->new();
    $schema_metadata->setInExtInfo($schemaExtInfo1);
    $schema_metadata->setOutExtInfo($schemaExtInfo2);
    
    # load the metadata of the Table
    
    my $dataExtInfoStr = Durin::Utilities::StringUtilities::removeEnter($disp->getline());
    my $dataExtInfo1 = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
    my $dataExtInfo2 = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
    #print "Table ExtInfo:",$dataExtInfo->makestring(),"\n";

    $metadata->setInExtInfo($dataExtInfo1);
    $metadata->setOutExtInfo($dataExtInfo2);
   
    # We read the schema from its corresponding file
    
    my $schema = $schemaExtInfo1->read();
    $schema->setMetadata($schema_metadata);
    
    $metadata->setSchema($schema);
    my $table = Durin::Data::FileTable->new();
    $table->setMetadata($metadata);
    




    #my $tableSchema = $metadata->getSchema();
    #print "TableSchema:",$tableSchema->makestring(),"\n";
    
    
    return $table;
  }

1;
