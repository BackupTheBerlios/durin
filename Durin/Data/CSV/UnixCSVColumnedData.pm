# Interface to a Windows CSV file

package Durin::Data::CSV::UnixCSVColumnedData;

use Durin::Data::CSV::ColumnedData;
use Durin::Data::FileStoredData;

@ISA = qw(Durin::Data::CSV::ColumnedData Durin::Data::FileStoredData);

use strict;

use Durin::Utilities::StringUtilities;
use Durin::Data::CSV::UnixSequentialData;
use Durin::Data::CSV::CSVColumnator;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    $self->setSequentialData(Durin::Data::CSV::UnixSequentialData->new());
    $self->setColumnator(Durin::Data::CSV::CSVColumnator->new());
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone ColumnedData\n";
  }
