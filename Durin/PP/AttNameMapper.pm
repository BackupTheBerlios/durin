package Durin::PP::AttNameMapper;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::PP::Transform::Attribute;
use Durin::PP::TableCopier;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{COPIER} = Durin::PP::TableCopier->new();
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
  my ($self) = @_;
  
  my $Input = $self->getInput();
  my $inTable = $Input->{TABLE_SOURCE};
  my $outTable = $Input->{TABLE_DESTINATION};
  my $mapping = $Input->{ATTNAME_MAPPING};
  my $i;
  my $trans;
  
  my $metadata = $inTable->getMetadata();
  my $schema = $metadata->getSchema();
  my $newSchema = $outTable->getMetadata()->getSchema();
  my $vector = [];

  #print "Jul\n";
  foreach my $attName (keys %$mapping)
    {
#      my $pos = $newSchema->getAttributeByName(
      #print "$attName\n";
      $newSchema->renameAttribute($attName,$mapping->{$attName});
    }

  $self->{COPIER}->setInput($Input);
  $self->{COPIER}->run();
  $self->setOutput($outTable);
}

1;
