# Copies a TableSchema in other file

use Durin::Classification::ClassedTableSchema;
use Durin::FlexibleIO::System;
use IO::File;

my $IOHandler = Durin::FlexibleIO::IORegistry->get("Durin::Classification::ClassedTableSchema","Standard",1);

my $file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name");
my $ts = $IOHandler->read($file);
$file->close();

$file_name = $ARGV[1];
$file = new IO::File;
$file->open(">$file_name");
$IOHandler->write($file,$ts);

print "Done\n";
