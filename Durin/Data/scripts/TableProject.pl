# Projects the categorical values in Credits dataset into a row .csv file (forgetting about metadata)

use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;

my ($file);
my $file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name");
my $table = Durin::Data::FileTable->read($file);
$file->close();

$file_name = $ARGV[1];
$file = new IO::File;
$file->open(">$file_name");

$table->open();
$table->applyFunction(sub {
			my ($row) = @_; 
			my ($new_row);
			
			$new_row = [$$row[0],$$row[2],$$row[3],$$row[4],$$row[5],$$row[7]];
			print $file join(',',@$new_row),"\n";});
$table->close();

$file->close();

print "Done\n";
