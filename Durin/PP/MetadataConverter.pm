# This file provides basic facility for converting metadata from the imported format to the STD format.

package Durin::PP::MetadataConverter;

use strict;

use Durin::Metadata::Table;
use Durin::Data::TableSchema;
use Durin::Metadata::Attribute;
use Durin::Metadata::AttributeType;
use Durin::Metadata::ATCategorical;
use Durin::Metadata::ATCreator;
use Durin::Utilities::StringUtilities;
use Durin::Classification::ClassedTableSchema;
use Durin::PP::Transform::Attribute;


# Receives a table schema and converts it into an STD Table metadata.

sub STDConversion
{
  my ($self,$sourceSchema,$class,$name) = @_;
  
  my $STDMetadata = Durin::Metadata::Table->new();
  
  my ($STDSchema);
  
  if (defined $class)
    {
      $STDSchema = Durin::Classification::ClassedTableSchema->new();
      $STDSchema->setClassByPos($class);
    }
  else
    {
      $STDSchema = Durin::Data::TableSchema->new();
    }
  
  my $nfields = $sourceSchema->getNumAttributes();
  my ($newAtt,$newAttType,$attType,$transVector);
  
  $transVector = [];
  foreach my $att (@{$sourceSchema->getAttributeList()})
    {
      $attType = $att->getType();
      
      $newAtt = Durin::Metadata::Attribute->new();
      $newAtt->setName($att->getName());
      
      if (Durin::Metadata::ATDate->isDate($att))
	{
	  $newAttType = Durin::Metadata::ATCreator->create("Number");
	  $newAttType->setHasUnknowns($attType->getHasUnknowns());
	  push @$transVector,PP::Transform::Attribute->getTransform("DateToNumber");
	}
      else
	{
	  $newAttType = $attType->clone();
	  push @$transVector,PP::Transform::Attribute->getTransform("Identity");
	}
      $newAtt->setType($newAttType);
      $STDSchema->addAttribute($newAtt);
    }
  
  $STDMetadata->setSchema($STDSchema);
  $STDMetadata->setName($name);
  return [$STDMetadata,$transVector];
}

return 1;

