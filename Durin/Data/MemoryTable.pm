package Durin::Data::MemoryTable;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

sub new_delta 
{     
    my ($class,$self) = @_;
    
    #print "Creating memory table\n";
    $self->{ROW_ARRAY} = [];
}

sub clone_delta
{  
    # my ($class,$self,$source) = @_;
    
    # Can this be done???
    print "Trying to clone a Table\n";
}

sub setMetadata($$)
{
    my ($self,$metadata) = @_;
    
    if (!$metadata->isa("Durin::Metadata::Table"))
    {
	die "Metadata for Durin::Data::MemoryTable should be derived from Durin::Metadata::Table\n";
    }
    $self->SUPER::setMetadata($metadata);
}

sub open
  {
    #
  }

sub close
  {
    #
  }

sub activate($)
{
    # Do nothing. For DB_tables the connection should be established here.
}

sub addRow($$)
{
    my ($self,$row) = @_;

    push(@{$self->{ROW_ARRAY}},$row);
}

sub getRow($$)
{
    my ($self,$row_number) = @_;
    
    return $self->{ROW_ARRAY}->[$row_number];
}

sub applyFunction($$)
{
    my ($self,$function) = @_;
    #print "\nAPPLYING\n";
    map {&$function($_)} (@{$self->{ROW_ARRAY}}) ;
}

sub removeRow($$)
{
    my ($self,$row_number) = @_;
    
    splice(@{$self->{ROW_ARRAY}},$row_number,1);
}

sub getSchema($)
{
    my ($self) = @_;

    return $self->getMetadata()->getSchema();
}
