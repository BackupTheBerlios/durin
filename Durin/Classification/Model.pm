
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
  die "Durin::Classification::Model::classify Pure virtual\n";
}


sub generateDataset {
  my ($self,$numRows)  = @_;
  
  my $dataset = Durin::Data::MemoryTable->new();
  my $metadataDataset = Durin::Metadata::Table->new();
  $metadataDataset->setSchema($self->getSchema());
  $metadataDataset->setName("tmp");
  $dataset->setMetadata($metadataDataset);
  
  my $count = 0;
  $dataset->open();
  for my $i (1..$numRows) {
    my $row = $self->generateObservation();
    #print join(",",@$row)."\n";
    $dataset->addRow($row);
  }
  $dataset->close();
  return $dataset;
}

sub generateObservation {
  my ($self) = @_;
  
  die "Durin::Classification::Model::generateObservation Pure virtual\n";
}

1;
