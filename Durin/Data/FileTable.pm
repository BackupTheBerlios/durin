# Module to access a table stored in a file, without bringing it entirely to main memory.

package Durin::Data::FileTable;

#use Durin::Data::MemoryTable;
use Durin::Data::SequentialTable;
#use Durin::Data::SchemedData;
use Durin::Utilities::StringUtilities;
use Durin::Data::Table;
#use Durin::Data::FileStoredData;

#@ISA = (Durin::Data::MemoryTable);# Durin::Data::FileStoredData);
@ISA = qw(Durin::Data::SequentialTable Durin::Data::Table);

use strict;

use IO::File;
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
    die "Trying to clone a Table\n";
}

sub open
  {
    my ($self,$access) = @_;
    
    #print "Opening File Table\n";

    if (!$access)
      {
	$access = "<";
      }
    
    my ($extInfo,$metadata);
    $metadata = $self->getMetadata();
    if ($access eq "<")
      {
	$extInfo = $metadata->getInExtInfo();
      }
    else
      {
	$extInfo = $metadata->getOutExtInfo();
      }
    #$extInfo->makestring();
  
    $extInfo->getDevice()->open($access) or die "Durin::Data::FileTable:Unable to open ExtInfo\n"; 
    $self->{FILE_HANDLE} = $extInfo->getDevice();
  }

#sub read($$)
#{
#    my ($class,$extInfo) = @_;
#    
#    my $metadata = Durin::Metadata::Table->read($extInfo);
#    my $self = Durin::Data::FileTable->new();
#
#}

sub close($)
{
    my ($self) = @_;

    #print "Executing close\n";
    $self->{FILE_HANDLE}->close;
}


sub addRow($$)
{
    my ($self,$row) = @_;

    # this is temporal, in the future should be better structured.

    # We replace all spaces by question marks...
    my $i = 0;
    my $item = $row->[$i];
    my $last = scalar(@$row);
    $self->PrintWithUnknownHandling($item);
    $i++;
    while ($i < $last)
      {
	$self->{FILE_HANDLE}->print(",");	
	$item = $row->[$i];
	$self->PrintWithUnknownHandling($item); 
	$i++;
      }
    $self->{FILE_HANDLE}->print("\n");
    #$self->{FILE_HANDLE}->print(join(',',@$row)."\n");
}

sub PrintWithUnknownHandling
  {
    my ($self,$item) = @_;
    
    if ((!defined($item)) || Durin::Utilities::StringUtilities::isSpaces($item))
      {
	$self->{FILE_HANDLE}->print("?");
      }
    else
      {
	$self->{FILE_HANDLE}->print($item);
      }
  }

sub getNextRow($)
{ 
    my ($self) = @_;

    # this is temporal, in the future should be better structured.
    my $line = $self->{FILE_HANDLE}->getline();
    return [split(/,/, Durin::Utilities::StringUtilities::removeEnter($line))];
}

sub start($)
{
    my ($self) = @_;
    
    $self->{FILE_HANDLE}->seek(0,0);
}

sub eof($)
{
    my ($self) = @_;

    return $self->{FILE_HANDLE}->eof();
}

#sub getRow($$)
#{
#    my ($self,$row_number) = @_;
#    
#    return $self->{ROW_ARRAY}->[$row_number];
#}

#sub applyFunction($$)
#{
#    my ($self,$function) = @_;
#    
#    my ($row);
#    
#    $self->start();
#    do 
#    {
#	$row = $self->getNextRow();
#	#print $row,"\n";
#	&$function($row);
#    }
#    until ($self->eof()); 
#}

#sub removeRow($$)
#{
#    my ($self,$row_number) = @_;
#    
#    splice($self->{ROW_ARRAY},$row_number,1);
#}
