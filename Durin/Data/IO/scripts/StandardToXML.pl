#!/home/cerquide/software/perl/bin/perl -w 
# This script receives as parameter a .std file that points to a table. It prints it on the stdout

use Durin::Data::IO::TSIOStandard;
use Durin::Classification::IO::CTSIOMineset;
use Durin::Data::IO::FTIOMineset;
use Durin::FlexibleIO::File;
use Durin::FlexibleIO::System;
#use Durin::Data::MemoryTable;
use IO::File;

my $dataset = $ARGV[0];
my $file_name = $dataset.".std";
$file = new IO::File;
$file->open("<$file_name") or die "Unable to open $file_name\n";
my $table = Durin::Data::FileTable->read($file);
$file->close();

my $metadata = $table->getMetadata();
print "Table read:",$metadata->getName(),"\n";
my $tableExtInfo = $metadata->getInExtInfo();
print "Table ExtInfo:",$tableExtInfo->makestring(),"\n";
my $tableSchema = $metadata->getSchema();
print "TableSchema:",$tableSchema->makestring(),"\n";

print "TableSchema ExtInfo:",$tableSchema->getMetadata()->getOutExtInfo()->makestring(),"\n";


$metadata->getSchema()->getMetadata()->getOutExtInfo()->getDevice()->setFileName($dataset.".structure.xml");
$metadata->getOutExtInfo()->getDevice()->setFileName($dataset.".data.xml");

my $schemaExtInfo = $table->getMetadata()->getSchema()->getMetadata()->getOutExtInfo();
#print "Yuhuuuu:".$schemaExtInfo.",",$schemaExtInfo->makestring(),"\n";
#print "TableSchema ExtInfo:",$table->getMetadata()->getSchema()->getMetadata()->getOutExtInfo()->makestring(),"\n";

$file_name = $dataset.".dataset.xml";
$file = new IO::File;
$file->open(">$file_name") or die "Unable to open $file_name\n";
$table->write($file,"XML");
$file->close();

print "Done\n";
