
# Classification model

package Durin::Classification::Model;

=head1 NAME

  Durin::Classification::Model - root of all the different classification models (trees, decision tables,...)

=head1 SYNOPSIS

  Contains the functions common to any classification model

=head1 DESCRIPTION

=over

=cut
use Durin::Components::Data;

@ISA = (Durin::Components::Data);

#use Durin::Metadata::Model;
use Durin::Components::Metadata;

sub new_delta
{
  my ($class,$self) = @_;
  
  $self->{SCHEMA} = undef;
  $self->setMetadata(Durin::Components::Metadata->new())
}

sub clone_delta
{ 
  my ($class,$self,$source) = @_;
  
  $self->setSchema($self->getSchema());
  #   $self->setMetadata($source->getMetadata()->clone());
}

=item setSchema/getSchema

  Sets/Gets the schema of the tables that the model is able to deal with.

=cut

sub setSchema($$)
{
  my ($self,$schema) = @_;
  
  $self->{SCHEMA} = $schema;
}

sub getSchema
{
    my ($self) = @_;
    
    return $self->{SCHEMA};
}

=item classify

  Given an instance, returns the class that the model predicts for it.

=cut

sub classify
{
  print "Durin::Classification::Model::classify Pure virtual\n";
}
