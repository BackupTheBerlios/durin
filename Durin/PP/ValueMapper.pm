package Durin::PP::ValueMapper;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::PP::Transform::Attribute;
use Durin::PP::TableTransformator;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{TRANSFORMATOR} = Durin::PP::TableTransformator->new();
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
  my $mapping = $Input->{VALUE_MAPPING};
  my $i;
  my $trans;
  
  my $metadata = $inTable->getMetadata();
  my $schema = $metadata->getSchema();
  my $newSchema = $outTable->getMetadata()->getSchema();
  my $vector = [];

  foreach my $attName (keys %$mapping)
    {
      #print "Processing attName: $attName\n";

      my $pos = $newSchema->getPositionByName($attName);
      $vector->[$pos] = CreateAttVM($mapping->{$attName});

      # complete the mapping with identity for undefined values
      
      my $att = $schema->getAttributeByName($attName);
      my $values = $att->getType()->getValues();
      
      foreach my $value (@$values)
	{
	  if (!exists $mapping->{$attName}->{$value})
	    {
	      $mapping->{$attName}->{$value} = $value;
	    }
	}

      # Change the schema
      my $valueList = [];
      my $valueHash = {};
      foreach my $value (keys %{$mapping->{$attName}})
	{
	  if (!exists $valueHash->{$mapping->{$attName}->{$value}})
	    {
	      #print "Processing value $value\n";
	      push @$valueList,$mapping->{$attName}->{$value};
	      $valueHash->{$mapping->{$attName}->{$value}} = 1;
	    }
	}
      $att = $newSchema->getAttributeByPos($pos);
      $att->getType()->setValues($valueList);
    }

  for ($i = 0 ; $i < $schema->getNumAttributes() ; $i++)
    {
      if (!defined $vector->[$i])
	{
	  $vector->[$i] = Durin::PP::Transform::Attribute->getTransform("Identity");
	}
    }
  $Input->{TRANSFORMATION_VECTOR} = $vector;
  $self->{TRANSFORMATOR}->setInput($Input);
  $self->{TRANSFORMATOR}->run();
  $self->setOutput($self->{TRANSFORMATOR}->getOutput());
}

sub CreateAttVM
  {
    my ($map) = @_;
    
    my $mapper = Durin::PP::Transform::Attribute->getTransform("ValueMap");
    $mapper->setValueMap($map);

    return $mapper;
  }

1;
