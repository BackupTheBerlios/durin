#!/home/cerquide/software/perl/bin/perl -w

use strict;

use DBI;
use Durin::PP::MetadataLearner;
use Durin::Data::TSIOStandard;
use IO::File;
use Durin::Metadata::Table;

my $dbh = DBI->connect("DBI:CSV:f_dir=.");
my $table_name = $ARGV[0];
print "Analysing $table_name \n";
my($query) = "SELECT * FROM $table_name";
my($sth) = $dbh->prepare($query);
$sth->execute();
$sth->finish();
$dbh->disconnect;

my $table_structure = Durin::PP::MetadataLearner->InduceStructure($sth,200);
print $table_structure->makestring(),"\n";

my $file_name = $ARGV[1];
my $file = new IO::File;
$file->open(">$file_name");
my $TIO = Durin::Data::TSIOStandard->new();
$TIO->write($file,$table_structure->getSchema());
close(FILE1);
open(FILE1,"<$file_name");
#
#$TIO->setFile(*FILE1{IO});
#my $new_table_structure = $TIO->read();
#close(FILE1);
#$TIO->setFile(*STDOUT{IO});
#$TIO->write($table_structure);
#$TIO->write($new_table_structure);
