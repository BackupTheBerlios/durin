# Interface to a Windows CSV file

package Durin::Data::CSV::WindowsCSVColumnedData;

use Durin::Data::CSV::ColumnedData;
use Durin::Data::FileStoredData;

@ISA = qw(Durin::Data::CSV::ColumnedData Durin::Data::FileStoredData);

use strict;

use Durin::Data::CSV::WindowsSequentialData;
use Durin::Data::CSV::CSVColumnator;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    $self->setSequentialData(Durin::Data::CSV::WindowsSequentialData->new());
    $self->setColumnator(Durin::Data::CSV::CSVColumnator->new());
    $self->setHasHeaders(1); # By default CSV files come with headers
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone ColumnedData\n";
  }
