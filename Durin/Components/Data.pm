package Durin::Components::Data;

=head1 NAME

  Durin::Components::Data - root of all data objects (tables, ...)

=head1 SYNOPSIS

  Contains the functions common to any data object

=head1 DESCRIPTION

=over

=cut

use Durin::Basic::NamedObject;
use Durin::FlexibleIO::Externalizable;

@ISA = qw(Durin::Basic::NamedObject Durin::FlexibleIO::Externalizable);

use strict;

use Durin::Components::Metadata;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{METADATA} = undef; 
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    print "Calling Durin::Components::Data\n";
    $self->setMetadata($source->getMetadata()->clone());
  }

=item setMetadata/getMetadata

  Sets/Gets the metadata of a data object.

=cut

sub setMetadata
  {
    my ($self,$metadata) = @_;
    
    $self->{METADATA} = $metadata;
  }

sub getMetadata
  {
    my ($self) = @_;
    
    return $self->{METADATA};
  }

=item setName/getName

  Sets/Gets the name of a data object (it just stores it in the metadata).

=cut

sub setName
  {
    my ($self,$name) = @_;
    
    $self->{METADATA}->setName($name);
  }

sub getName
  {
    my ($self) = @_;
    
      return $self->{METADATA}->getName();
  }

=back
