package Durin::Classification::ClassedTableSchema;

use Durin::Data::TableSchema;

@ISA = (Durin::Data::TableSchema);

use strict;

use Durin::Metadata::Attribute;

sub new_delta 
{ 
    my ($class,$self) = @_;
  
    $self->{CLASS} = undef;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
    
    #print "Calling Durin::Classification::ClassedTableSchema\n";
    $self->setClassByPos($source->getClassPos());
}

sub setClassByName($$)
{
    my ($self,$class) = @_;

    die "Durin::Data::ClassedTable->setClassByName NYI\n";
}

sub setClassByPos($$)
{
    my ($self,$class) = @_;

    $self->{CLASS} = $class;
}

sub getClassPos($)
{
    my $self = shift;
    
    return $self->{CLASS};
} 

sub getClass($) {
  my ($self) = @_;

  return $self->getAttributeByPos($self->getClassPos());
}

sub generateCompleteDatasetWithoutClass {
  my ($self)  = @_;
  
  my $dataset = Durin::Data::MemoryTable->new();
  my $metadataDataset = Durin::Metadata::Table->new();
  $metadataDataset->setSchema($self);
  $metadataDataset->setName("tmp");
  $dataset->setMetadata($metadataDataset);
  
  my $attTypes = [];
  my $actualValueIndexes = [];
  my $row = [];
  foreach my $att (@{$self->getAttributeList()}) {
    my $attType = $att->getType();
    push @$attTypes,$attType;
    push @$actualValueIndexes,0;
    push @$row,$attType->getValue(0);
  }
  my $classPos = $self->getClassPos();
  $dataset->open();
  do {
    if ($actualValueIndexes->[$classPos] == 0){
      #print "Generated ".join(',',@$row)."\n";
      $dataset->addRow($row);
      my @tmp =  @$row;
      $row = \@tmp;
    }
    #print "Bef\n";
    $self->increaseAndGenerateObservation($actualValueIndexes,$attTypes,$row);
    #print "Aft\n";
  } while ($self->stillMoreObservations($actualValueIndexes));
  $dataset->close();
  
  return $dataset;
} 

sub makestring($)
{
    my $self = shift;
    
    return $self->SUPER::makestring();
}

1;
