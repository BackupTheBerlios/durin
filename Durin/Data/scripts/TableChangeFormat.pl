# Tries to write a file in Cerquides format.

use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;

my $IOHandler = Durin::FlexibleIO::IORegistry->get("Durin::Data::FileTable","Standard",1);

my $file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name");
my $table = $IOHandler->read($file);
$file->close();

$new_file_name = $ARGV[1];
print "I have read the file table: ",$table->getMetadata()->getName()," from $file_name in Standard format. I will write it into $new_file_name in Cerquides format\n";

my $IOHandler = Durin::FlexibleIO::IORegistry->get("Durin::Data::FileTable","Cerquides",1);

print "I am going to write it in $file_name\n";
$file = new IO::File;
$file->open(">$new_file_name");
$IOHandler->write($file,$table);
print "Done\n";
