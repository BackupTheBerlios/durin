# Windows file where rows are separated by "\n";

package Durin::Data::CSV::UnixSequentialData;

use Durin::Data::CSV::SequentialData;

@ISA = (Durin::Data::CSV::SequentialData);

use strict;
use Durin::Utilities::StringUtilities;

sub new_delta 
  {     
    my ($class,$self) = @_;

    $self->{FILE_HANDLE} = undef;
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone WindowsRowedData\n";
  }

sub open
  {
    #
    my ($self,$access) = @_;
    
    if (!$access)
      {
	$access = "<";
      }
    
    my ($extInfo,$metadata);
    $metadata = $self->getMetadata();
    if ($access eq "<")
      {
	$extInfo = $metadata->getInExtInfo()->getDevice();
      }
    else
      {
	$extInfo = $metadata->getOutExtInfo()->getDevice();
      }
    $extInfo->open($access) or die "Durin::Data::CSV::UnixSequentialData: Unable to open ExtInfo\n"; 
    $self->{FILE_HANDLE} = $extInfo;
  }

sub close
  {
    my ($self) = @_;
    
    $self->{FILE_HANDLE}->close;
  }

sub activate
  {
    # Do nothing. For DB_tables the connection should be established here.
  }

sub addRow
  {
    my ($self,$row) = @_;
    
    $self->{FILE_HANDLE}->print($row."\n");
  }

sub getNextRow
  { 
    my ($self) = @_;
  
    # this is temporal, in the future should be better structured.
    my $line = $self->{FILE_HANDLE}->getline();
    return Durin::Utilities::StringUtilities::removeEnter($line);
  }

sub start
  {
    my ($self) = @_;
    
    $self->{FILE_HANDLE}->seek(0,0);
  }

sub eof
  {
    my ($self) = @_;
    
    return $self->{FILE_HANDLE}->eof();
  }

#sub removeRow
#  {
#    my ($self,$row_number) = @_;
    
    #splice(@{$self->{ROW_ARRAY}},$row_number,1);
#  }
