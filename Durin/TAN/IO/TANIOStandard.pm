package Durin::TAN::IO::TANIOStandard;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "Durin::TAN::TAN";
$IO_FORMAT = "Standard";

use strict;

use Durin::TAN::TAN;
#use Durin::FlexibleIO::ExtInfo;
#use Durin::Metadata::Table;
use Durin::Utilities::StringUtilities;

sub write
{
    my ($class,$disp,$TAN) = @_;
    
    die "NYI\n";
}

sub read
{
    my ($class,$disp) = @_;
    
      die "NYI\n";
}

1;
