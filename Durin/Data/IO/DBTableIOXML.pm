package Durin::Data::IO::DBTableIOXML;

use Durin::Components::IO::DataXML;

@ISA = (Durin::Components::IO::DataXML);
$IO_CLASS = "Durin::Data::DBTable";
$IO_FORMAT = "XML";

use strict;

use Durin::Data::DBTable;
use Durin::FlexibleIO::ExtInfo;
use Durin::Metadata::Table;
use Durin::Utilities::StringUtilities;
use XML::Generator;
use XML::DOM;

sub write
  {
    my ($class,$disp,$table) = @_;
    
    my $metadata = $table->getMetadata();
    my $schema = $metadata->getSchema();
    my $schemaExtInfo = $schema->getMetadata()->getOutExtInfo(); 
    my $doc = new XML::DOM::Document;
    
    my $decl = new XML::DOM::XMLDecl;
    $decl->setVersion("1.0");
    $doc->setXMLDecl($decl);
    my $item = $doc->createElement("DataItem"); 
    
    # format
    
    my $format = $doc->createAttribute("format");
    $format->setValue("XML");
    $item->setAttributeNode($format);
    
    # type

    my $type= $doc->createAttribute("type");
    $type->setValue("Durin::Data::DBTable");
    $item->setAttributeNode($type);
    
    # metadata
   
    my $metadataNode= $doc->createElement("metadata");
    my $name = $doc->createElement("name");
    $name->appendChild($doc->createTextNode($metadata->getName()));
    $metadataNode->appendChild($name);

    my $schemaNode = $doc->createElement("schema");
    my $temp = $schemaExtInfo->makestring();
    $schemaNode->appendChild($doc->createTextNode($temp));
    $metadataNode->appendChild($schemaNode);
    $item->appendChild($metadataNode);
    
    # data
    
    my $dataOutExtInfoStr = $metadata->getOutExtInfo()->makestring();
    my $dataNode= $doc->createElement("data");
    $dataNode->appendChild($doc->createTextNode($dataOutExtInfoStr));
    $item->appendChild($dataNode);
    
    # Main node
    $doc->appendChild($item);
    $disp->print($doc->toString);
    $disp->close();
    
    #my $dataOutExtInfo = $metadata->getOutExtInfo();
    #my $dataInExtInfo = $metadata->getInExtInfo();
    #$disp->print($XMLGen->data($XMLGen->ExtInfo($dataOutExtInfo->makestring()))."\n");
    
    #$disp->print($dataOutExtInfo->makestring(),"\n");
    
    # Now we write the schema into its corresponding file
    
    $schemaExtInfo->write($schema);
  }

sub readFromXML
  { 
    my ($class,$doc) = @_;
    
    my $metadataNode = $doc->getElementsByTagName("metadata")->item(0);
    my $data = $doc->getElementsByTagName("data")->item(0);
    my $name = $metadataNode->getElementsByTagName("name")->item(0)->getFirstChild()->getData();
    
    print "Name: $name\n";
    
    my $metadata = Durin::Metadata::Table->new();
    $metadata->setName($name);
    
    # Load the metadata of the TableSchema
    
    my $schemaExtInfoStr = $metadataNode->getElementsByTagName("schema")->item(0)->getFirstChild()->getData();
    
    my $schemaExtInfo1 = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
    my $schemaExtInfo2 = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
    
    my $schemaMetadata = Durin::Components::Metadata->new();
    $schemaMetadata->setInExtInfo($schemaExtInfo1);
    $schemaMetadata->setOutExtInfo($schemaExtInfo2);
    
    # load the metadata of the Table
    
    my $dataExtInfoStr = $doc->getElementsByTagName("data")->item(0)->getFirstChild()->getData();
    
    my $dataExtInfo1 = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
    my $dataExtInfo2 = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
    #print "Table ExtInfo:",$dataExtInfo->makestring(),"\n";
    
    $metadata->setInExtInfo($dataExtInfo1);
    $metadata->setOutExtInfo($dataExtInfo2);
    
    # We read the schema from its corresponding file
    
    my $schema = $schemaExtInfo1->read();
    $schema->setMetadata($schemaMetadata);
    $metadata->setSchema($schema);
    my $table = Durin::Data::DBTable->new();
    $table->setMetadata($metadata);

    #my $tableSchema = $metadata->getSchema();
    #print "TableSchema:",$tableSchema->makestring(),"\n";
    
    return $table;
  }

#sub read
#  {
#    my ($class,$disp) = @_;

#    "Not Implemented\n";
    #my $parser = new XML::DOM::Parser;
    #my $doc = $parser->parse($disp);
    
    #if ($disp->getline() ne "Format: Durin::Data::FTIOStandard\n")
    #{
#	die "Durin::Data::FTIOStandard Incorrect format\n";
#    }
#    my $name = Durin::Utilities::StringUtilities::removeEnter($disp->getline());

#    #print "Name: $name\n";

#    my $metadata = Durin::Metadata::Table->new();
#    $metadata->setName($name);

#    # Load the metadata of the TableSchema
    
 #   my $schemaExtInfoStr = $disp->getline();
 #   $schemaExtInfoStr =~ /^(.*)\n$/;
 #   $schemaExtInfoStr = $1;
 #   my $schemaExtInfo1 = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
    #   my $schemaExtInfo2 = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
 #   
 #   my $schema_metadata = Durin::Components::Metadata->new();
 #   $schema_metadata->setInExtInfo($schemaExtInfo1);
 #   $schema_metadata->setOutExtInfo($schemaExtInfo2);
    
 #   # load the metadata of the Table
    
 #   my $dataExtInfoStr = Durin::Utilities::StringUtilities::removeEnter($disp->getline());
 #   my $dataExtInfo1 = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
 #   my $dataExtInfo2 = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
 #   #print "Table ExtInfo:",$dataExtInfo->makestring(),"\n";

  #  $metadata->setInExtInfo($dataExtInfo1);
  #  $metadata->setOutExtInfo($dataExtInfo2);
  # 
  #  # We read the schema from its corresponding file
  #  
  #  my $schema = $schemaExtInfo1->read();
  #  $schema->setMetadata($schema_metadata);
  #  
  #  $metadata->setSchema($schema);
  #  my $table = Durin::Data::FileTable->new();
  #  $table->setMetadata($metadata);
    




    #my $tableSchema = $metadata->getSchema();
    #print "TableSchema:",$tableSchema->makestring(),"\n";
    
    
   # return $table;
#  }

1;
