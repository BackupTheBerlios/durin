# This is the a abstraction for a file that we know is made of rows and we know how to separate those rows, but we do not know how to separate the columns into those rows.

package Durin::Data::CSV::SequentialData;

#use Durin::Basic::MIManager;

#@ISA = (Durin::Basic::MIManager);

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

sub new_delta 
  {     
    my ($class,$self) = @_;
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    die "Trying to clone SequentialData\n";
  }

#sub open
#  {
#    #
#  }

#sub close
#  {
#    #
#  }

#sub activate
#  {
#    # Do nothing. For DB_tables the connection should be established here.
#  }

sub addRow($$)
  {
    my ($self,$row) = @_;
    
    #push(@{$self->{ROW_ARRAY}},$row);
  }

sub getNextRow($$)
  {
    my ($self,$row_number) = @_;
    
    #return $self->{ROW_ARRAY}->[$row_number];
  }

sub start
  {
    my ($self) = @_;
    
    #$self->{FILE_HANDLE}->seek(0,0);
  }

sub eof
  {
    my ($self) = @_;
    
    #return $self->{FILE_HANDLE}->eof();
  }

sub applyFunction
  {
    my ($self,$function) = @_;
    
    my ($row);
    
    $self->start();
    do 
      {
	$row = $self->getNextRow();
	&$function($row);
      }
    until ($self->eof()); 
  }

#sub removeRow
#  {
#   my ($self,$row_number) = @_;
    
    #splice(@{$self->{ROW_ARRAY}},$row_number,1);
#  }
