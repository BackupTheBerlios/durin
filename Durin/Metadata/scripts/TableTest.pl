#!/home/cerquide/software/perl/bin/perl -w

use strict;

use Durin::Metadata::Table;
use Durin::Metadata::Attribute;

my $table = Durin::Metadata::Table->new();
my $att1 = Durin::Metadata::Attribute->new();
my $att2 = Durin::Metadata::Attribute->new();

$att1->setName("Att1");
$att1->setType("Type1");
$att2->setName("Att2");
$att2->setType("Type2");

$table->addAttribute($att1);
$table->addAttribute($att2);

print $table->getAttributeByName("Att1")->makestring() , "\n";
print $table->getAttributeByPos(0)->makestring() , "\n";
print $table->getAttributeByName("Att2")->makestring() , "\n";
print $table->getAttributeByPos(1)->makestring() , "\n";
