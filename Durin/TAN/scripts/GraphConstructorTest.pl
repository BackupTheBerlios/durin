# Tests GraphConstructor functionality
use Durin::FlexibleIO::System;
use Durin::Data::MemoryTable;
use IO::File;
use Durin::ProbClassification::ProbApprox::Counter;
use Durin::TAN::GraphConstructor;

$file_name = $ARGV[0];
$file = new IO::File;
$file->open("<$file_name") or die "No pude\n";
my $table = Durin::Data::FileTable->read($file);
$file->close();

print "CTS loaded\n";

my $bc = Durin::ProbClassification::ProbApprox::Counter->new();

$bc->setInput($table);
$bc->run();
my @tablesRef = @{$bc->getOutput()};

#print "I have counted: ", ${$tablesRef[0]}, "\n";
#my %pepe  = %{$tablesRef[1]};
#foreach my $a (keys %pepe)
#  {
#    print "class :",$pepe{$a},"\n";
#  }

my $gcons = Durin::TAN::GraphConstructor->new();
my ($Input);

$Input->{ARRAYOFTABLES} = \@tablesRef;
$Input->{SCHEMA} = $table->getMetadata()->getSchema();
$gcons->setInput($Input);
$gcons->run();
my $graph = $gcons->getOutput();

my $edgesRef =  $graph->getEdges();

foreach my $e (@$edgesRef)
{
    print join (',',@$e),"\n";
}

#my (%edges) = %{$edgesRef};
#foreach my $e1 (keys %edges)
#{
#    my ($edd) = $edges{$e1};
#    foreach my $e2 (keys %$edd)
#    {
#	print "$e1,$e2,$edges{$e1}{$e2}\n";
#    }
#}   

print "Done\n";
