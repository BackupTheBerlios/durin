# This script receives as parameter a .std file that points to a table. It prints it on the stdout

use Durin::Data::TSIOStandard;
use Durin::FlexibleIO::File;

use Durin::FlexibleIO::System;
#use Durin::Data::MemoryTable;
use IO::File;

my $file_name = $ARGV[0];
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

#print "TableSchema ExtInfo:",$tableSchema->getMetadata()->getExtInfo()->makestring(),"\n";



#print "Proceeding to print it:\n";

# print the table contents

$table->open();
$table->applyFunction(sub {my ($row) = @_; print join(',',@$row),"\n";});
$table->close();

# write the table in new files

# We change the file for the schema.

$metadata->getSchema()->getMetadata()->getOutExtInfo()->getDevice()->setFileName("a.names");
$metadata->getOutExtInfo()->getDevice()->setFileName("a.data");

$file_name = $ARGV[1];
$file = new IO::File;
$file->open(">$file_name") or die "Unable to open $file_name\n";
$table->write($file);
$file->close();

print "Done\n";
