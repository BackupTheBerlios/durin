package Durin::Data::IO::FTIOMineset;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "Durin::Data::FileTable";
$IO_FORMAT = "Mineset";

use strict;

use Durin::Data::FileTable;
use Durin::FlexibleIO::ExtInfo;
use Durin::Metadata::Table;
use Durin::Utilities::StringUtilities;

sub write
  {
    my ($class,$disp,$table) = @_;
    
    #print "@@@@@@@@@ Here I am\n";

    my $metadata = $table->getMetadata();
    my $schema = $metadata->getSchema();
    my $schemaExtInfo = $schema->getMetadata()->getOutExtInfo();
    my $dataExtInfo = $metadata->getOutExtInfo();
    
    # Now we write the schema into its corresponding file
    
    #print $schemaExtInfo->makestring()."\n";
    my $dev = $schemaExtInfo->getDevice();
    $dev->open(">");
    $schema->write($dev,"Mineset");
    $dev->close();
    
    # And now we write the database into its corresponding file.

    my $attList = $schema->getAttributeList();
    my $classNum = $schema->getClassPos();
    $table->open();
    $dev = $dataExtInfo->getDevice();
    $dev->open(">");
    $table->applyFunction(
			  sub 
			  {
			    my ($row) = @_;
			    
			    # mineset does not like dots, so we remove them.

			    my $i = 0;
			    foreach  my $att (@$attList)
			      {
				if (!Metadata::ATNumber->isNumber($att))
				  {
				    $row->[$i] =~ tr/\./\-1/;
				    $row->[$i] =~ tr/\|/\-2/;
				    $row->[$i] =~ tr/\?/\-3/;
				  }
				$i++;
			      }
			    
			    my $classValue = $row->[$classNum];
			    splice(@$row,$classNum,1);
			    push @$row,($classValue);
				 
			    $dev->print(join(',',@$row),"\n");
			  }
			 );
    $dev->close();
    $table->close();
  }

sub read
  {
    my ($class,$disp) = @_;

    #die "Durin::Data::FTIOMineset: NYI\n";
    
    $disp->useNames();
    $disp->open("<");
    my $line = getNextLine($disp);
    
    while (!Utilities::StringUtilities::isEmptyLine($line))
      {
	
	$line = getNextLine($disp);
      }
    
    #if ($disp->getline() ne "Format: Durin::Data::FTIOMineset\n")
    #{
#	die "Durin::Data::FTIOMineset Incorrect format\n";
#    }
#    my $name = Durin::Utilities::StringUtilities::removeEnter($disp->getline());

    #print "Name: $name\n";

#    my $metadata = Durin::Metadata::Table->new();
#    $metadata->setName($name);

    # Load the metadata of the TableSchema
    
 #   my $schemaExtInfoStr = $disp->getline();
 #   $schemaExtInfoStr =~ /^(.*)\n$/;
 #   $schemaExtInfoStr = $1;
  #  my $schemaExtInfo = Durin::FlexibleIO::ExtInfo->create($schemaExtInfoStr);
   

   # my $schema_metadata = Durin::Components::Metadata->new();
   # $schema_metadata->setExtInfo($schemaExtInfo);
    
    ## load the metadata of the Table
    
    #my $dataExtInfoStr = Durin::Utilities::StringUtilities::removeEnter($disp->getline());
    #my $dataExtInfo = Durin::FlexibleIO::ExtInfo->create($dataExtInfoStr);
    ##print "Table ExtInfo:",$dataExtInfo->makestring(),"\n";

    #$metadata->setExtInfo($dataExtInfo);
   
    ## We read the schema from its corresponding file
    
    #my $schema = $schemaExtInfo->read();
    #$schema->setMetadata($schema_metadata);
    
    #$metadata->setSchema($schema);
    #my $table = Durin::Data::FileTable->new();
    #$table->setMetadata($metadata);
    
    #my $tableSchema = $metadata->getSchema();
    ##print "TableSchema:",$tableSchema->makestring(),"\n";
    

    #return $table;
  }

1;
