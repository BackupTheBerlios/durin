package Durin::FlexibleIO::DataTypeMappingRegistry;

my $map;

sub BEGIN
  {
    print "Initializing DataTypeMappingRegistry\n";
    $map->{"Durin::Data::ClassedTableSchema"} = "Durin::Classification::ClassedTableSchema";
  }

use strict;

#$map->{"Durin::Data::ClassedTableSchema"} = "Durin::Classification::ClassedTableSchema";

sub getMapping
  {
    my ($self,$name) = @_;
    
    my $mappedClass = $map->{$name};
    if (defined($mappedClass))
      {
	#print "The map of $name is:", $mappedClass,"\n";
	#print keys(%$map),"\n";
	return $mappedClass;
      }
    else
      
      {
	return $name;
      }
  }

1;
