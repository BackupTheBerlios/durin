package Durin::Data::STDFileTable;

use Durin::Data::FileTable;

@ISA = (Durin::Data::FileTable);

use strict;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    #$self->{FILE_HANDLE} = undef;
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone a Table\n";
  }

sub setExtInfo
  {
    my ($self,$outputStrFileName,$outputCSVFileName) = @_;
    
    print "Setting Ext Info in STDFileTable [$outputStrFileName,$outputCSVFileName]\n";
    my $tableMetadata = $self->getMetadata();

    my $tableExtInfo1 = Durin::FlexibleIO::ExtInfo->create("Data::FileTable Standard [FlexibleIO::File $outputCSVFileName]");
    my $tableExtInfo2 = Durin::FlexibleIO::ExtInfo->create("Data::FileTable Standard [FlexibleIO::File $outputCSVFileName]");
    $tableMetadata->setInExtInfo($tableExtInfo1);
    $tableMetadata->setOutExtInfo($tableExtInfo2);
    
    my $schemaMetadata = Durin::Components::Metadata->new();
    my $schemaExtInfo1 = Durin::FlexibleIO::ExtInfo->create("Classification::ClassedTableSchema Standard [FlexibleIO::File $outputStrFileName]");
    my $schemaExtInfo2 = Durin::FlexibleIO::ExtInfo->create("Classification::ClassedTableSchema Standard [FlexibleIO::File $outputStrFileName]");
    $schemaMetadata->setInExtInfo($schemaExtInfo1);
    $schemaMetadata->setOutExtInfo($schemaExtInfo2);
    $tableMetadata->getSchema()->setMetadata($schemaMetadata);
    
  }

#sub getExtInfo
#  {
#    my ($self) = @_;
#    
#    return [$tableMetadata->getInExtInfo()->
#  }
