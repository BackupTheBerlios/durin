# File to test ClassedTableSchemas

use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use Durin::Classification::ClassedTableSchema;
use IO::File;

my $file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name");
my $table = Durin::Data::FileTable->read($file);
$file->close();

my $metadata = $table->getMetadata();
print "Table name:",$metadata->getName(),"\n";

my $schema = $metadata->getSchema();
my $cts = Durin::Classification::ClassedTableSchema->new();

 Durin::Data::TableSchema->clone_rec($cts,$schema);

my $cts_metadata = $cts->getMetadata();


print "Original: ",$schema->makestring(),"\n";
print "Clone: ",$cts->makestring(),"\n";

$extInfo = $cts_metadata->getExtInfo();
$extInfo->setDataType(ref($cts));
$extInfo->setDevice("C" . $schema->getMetadata()->getExtInfo()->getDevice());

print "Original extInfo: ",$schema->getMetadata()->getExtInfo()->makestring(),"\n";
print "Clone extInfo: ",$cts_metadata->getExtInfo()->makestring(),"\n";

$cts->setClassByPos(5);
$metadata->setSchema($cts);


$file_name = "C".$ARGV[0];
$file = new IO::File;
$file->open(">$file_name") or die "No pude\n";
Data::FTIOStandard->write($file,$table);
$file->close();

print "CTS saved\n";

$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table2 = Durin::Data::FileTable->read($file);
$file->close();

print "CTS loaded\n";

$file = new IO::File;
$file->open(">$file_name") or die "No pude\n";
Data::FTIOStandard->write($file,$table2);
$file->close();

print "CTS saved again\n";

#$table->open();
#$table->applyFunction(sub {my ($row) = @_; print join(',',@$row),"\n";});
#$table->close();

#$table->write();

print "Done\n";
