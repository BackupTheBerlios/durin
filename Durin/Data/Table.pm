package Durin::Data::Table;

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
    die "Trying to clone a Table\n";
}

sub setMetadata($$)
{
    my ($self,$metadata) = @_;
    
    if (!$metadata->isa("Metadata::Table"))
    {
	die "Metadata for Durin::Data::MemoryTable should be derived from Durin::Metadata::Table\n";
    }
    $self->SUPER::setMetadata($metadata);
}

sub open
  {
    die "Pure Virtual\n";
  }

sub close
  {
    die "Pure Virtual\n";
  }

sub activate($)
{
   die "Pure Virtual\n";
   # Do nothing. For DB_tables the connection should be established here.
}

sub applyFunction($$)
{
    my ($self,$function) = @_;
    
    die "Pure Virtual\n";
}

sub getSchema($)
{
    my ($self) = @_;

    return $self->getMetadata()->getSchema();
}

1;
