package Durin::Metadata::Table;

use base Durin::Components::Metadata;

#@ISA = (Durin::Components::Metadata);

use strict;

use Durin::Data::TableSchema;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{TABLE_SCHEMA} = undef;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
    
    $self->setSchema($source->getSchema()->clone()) ;
}

sub read($$)
{
    my ($class,$extInfo) = @_;
    
    my $self = Durin::Metadata::Table->new();
    $self->SUPER::read($extInfo);
    $self->read_delta($extInfo);
}

sub read_delta($$)
{
    my ($self,$extInfo) = @_;
    
    $self->setSchema(Durin::Data::TableSchema->read($extInfo));
}

sub write($$)
{ 
    my ($self,$extInfo) = @_;
    
    $self->SUPER::write($extInfo);
    $self->write_delta($extInfo);
}

sub write_delta($$)
{ 
    my ($self,$extInfo) = @_;
    
    $self->getSchema()->write($extInfo);
}

sub setSchema($$)
{
      my ($self,$schema) = @_;
      
      $self->{TABLE_SCHEMA} = $schema;
}

sub getSchema($)
{
    my $self = shift;
    
    return $self->{TABLE_SCHEMA};
}
    
sub makestring($)
{
    my $self = shift;
 
    return $self->getSchema()->makestring();
}

1;
