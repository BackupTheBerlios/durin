#!/home/cerquide/software/perl/bin/perl -w

use strict;
use Durin::Metadata::Attribute;

my $att = Durin::Metadata::Attribute->new();

$att->setName("Attribute1");
$att->setType(["Hola","Adios"]);

print "Name:",$att->getName(),"\n";
print "Type:",$att->getType(),"\n";
