# Classification model that contains other classification models

package Durin::Classification::CompositeModel;

use strict;
use wartnings;

=head1 NAME

Durin::Classification::CompositeModel - serves as a container for different classification models.

=head1 SYNOPSIS

Provides the basic functionality of an ensemble.

=head1 DESCRIPTION

=over

=cut
use Durin::Classification::Model;

@Durin::Classification::CompositeModel::ISA = (Durin::Classification::Model);

#use Durin::Metadata::Model;
use Durin::Components::Metadata;

sub new_delta {
  my ($class,$self) = @_;

  $self->{MODEL_LIST} = [];
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
  
  $self->setSchema($self->getSchema());
  #   $self->setMetadata($source->getMetadata()->clone());
}

sub setSchema($$)
{
  my ($self,$schema) = @_;
  
  die "Unable to setSchema in Durin::Classification::CompositeModel";
}

sub getSchema {
  my ($self) = @_;
  
  if (scalar @{$self->{MODEL_LIST}}) {
    return $self->{MODEL_LIST}->[0];
  } else {
    return undef;
  }
}

=item classify

  Given an instance, returns the class that the model predicts for it.

=cut

sub classify
{
  die "Durin::Classification::CompositeModel::classify Pure virtual\n";
}
=item compositeClassify

Given an instance, returns a list with the class that each model in the model list predicts for it.

=cut

sub compositeClassify ($$) {
  my ($self,$row) = @_;

  my $classList = [];
  my $class;
  foreach my $model (@{$self->{MODEL_LIST}}) {
    $class = $model->classify($row);
    push @$classList,$class;
  }
  return $classList;
}
