# This is the a abstraction for a file that we know is made of rows and columns and we know how to separate those rows and columns.

package Durin::Data::CSV::ColumnedData;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

use IO::File;
use Durin::Utilities::StringUtilities;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    $self->{SEQUENTIAL_DATA} = undef;
    $self->{COLUMNATOR} = undef;
    $self->setHasHeaders(1);
    $self->{HEADERS} = [];
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone ColumnedData\n";
  }

sub setMetadata
  {
    my ($self,$metadata) = @_;
    
    $self->getSequentialData()->setMetadata($metadata);
  }

sub getMetadata
  {
    my ($self) = @_;
    
    return $self->getSequentialData()->getMetadata();
  }

sub setSequentialData
  {
    my ($self,$rd) = @_;
    
    $self->{SEQUENTIAL_DATA} = $rd;
  }

sub getSequentialData
  {
    my ($self) = @_;
    
    return $self->{SEQUENTIAL_DATA};
  }

sub setColumnator
  {
    my ($self,$columnator) = @_;
    
    $self->{COLUMNATOR} = $columnator;
  }

sub getColumnator
  {
    my ($self) = @_;
    
    return $self->{COLUMNATOR};
  }

sub close
  {
    my ($self) = @_;

    $self->{SEQUENTIAL_DATA}->close;
  }


sub addRow
  {
    my ($self,$row) = @_;
    
    $self->{SEQUENTIAL_DATA}->addRow($self->{COLUMNATOR}->ToString($row));
  }

sub getNextRow
  { 
    my ($self) = @_;
    
    my $line = $self->{SEQUENTIAL_DATA}->getNextRow();
    #print "Line:$line\n";
    my $r = $self->{COLUMNATOR}->ToArray($line);
    #print "Res: @$r\n";
    return $r;
  }

sub eof
  {
    my ($self) = @_;
    
    return $self->{SEQUENTIAL_DATA}->eof();
  }

sub applyFunction
  {
    my ($self,$function) = @_;
   
    my ($row);
    
    $self->start();
    #print "Starting\n";
    do 
      {
	$row = $self->getNextRow();
	#print "Row: @$row\n";
	&$function($row);
      }
    until ($self->eof()); 
  }

sub setHasHeaders
  { 
    my ($self,$state) = @_;
    
    $self->{HAS_HEADERS} = $state;
  }


sub getHasHeaders
  {
    my ($self) = @_;
    
    return $self->{HAS_HEADERS};
  }

sub getHeaderMap
  {
    my ($self) = @_;
    
    return $self->{HEADERS_MAP};
  }


sub getHeaders
  {
     my ($self) = @_;
    
     return $self->{HEADERS};
   }

sub setHeaders
  {
    my ($self,$headersRow) = @_;
    
    $self->{HEADERS} = $headersRow;
    $self->{HEADERS_MAP} = {};
    my $i = 0;
    foreach my $field (@$headersRow)
      {
	$self->{HEADERS_MAP}->{$field} = $i;
	$i++;
      }
  }

sub start
  {
    my ($self) = @_;

    $self->{SEQUENTIAL_DATA}->start();
    if ($self->getHasHeaders())
      {
	$self->setHeaders($self->getNextRow());
      }
  }

sub open
  {
    my ($self,$access) = @_;
    
    $self->{SEQUENTIAL_DATA}->open($access);
    if ($access eq "<")
      {
	if ($self->getHasHeaders())
	  {
	    $self->setHeaders($self->getNextRow());
	  }
      }
    if ($access eq ">")
      {
	if ($self->getHasHeaders())
	  {
	    $self->addRow($self->getHeaders());
	  }
      }
  }
