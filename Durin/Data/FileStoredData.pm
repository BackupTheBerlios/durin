# Interface to a anything stored into a file. Adjective class.

package Durin::Data::FileStoredData;

# Whatever is a FileStoredData should be data from some other place, not inherited from here.

#use Durin::Components::Data;

#@ISA = (Durin::Components::Data);

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

use strict;

sub new_delta 
  {     
    my ($class,$self) = @_;    
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone ColumnedData\n";
  }

sub setInFileName
  {
    my ($self,$fileName) = @_;

    my $metadata = $self->getMetadata();
    if (!defined $metadata)
      {
	$metadata = Durin::Components::Metadata->new();
	$self->setMetadata($metadata);
      }
    if (!defined $metadata->getInExtInfo())
      {
	my $extInfo = Durin::FlexibleIO::ExtInfo->create("Components::Data Standard [FlexibleIO::File $fileName]");
	$metadata->setInExtInfo($extInfo);
      }
  }

sub setOutFileName
  {
    my ($self,$fileName) = @_;

    my $metadata = $self->getMetadata();
    if (!defined $metadata)
      {
	$metadata = Durin::Components::Metadata->new();
	$self->setMetadata($metadata);
      }
    if (!defined $metadata->getOutExtInfo())
      {
	my $extInfo = Durin::FlexibleIO::ExtInfo->create("Components::Data Standard [FlexibleIO::File $fileName]");
	$metadata->setOutExtInfo($extInfo);
      }
  }
