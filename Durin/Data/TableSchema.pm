package Durin::Data::TableSchema;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

use Durin::Metadata::Attribute;

sub new_delta 
{
    my ($class,$self) = @_;
    
    $self->{ATTRIBUTES_HASH} = {};
    $self->{ATTRIBUTES_LIST} = [];
    $self->{ATTRIBUTES_NUMBER} = 0;
}

sub clone_delta($$)
{
    my ($class,$self,$source) = @_;
 
    #print "Calling Durin::Data::TableSchema\n";
    my ($att);
    foreach $att (@{$source->getAttributeList()})
    {
	$self->addAttribute($att->clone());
    }
}

sub addAttribute($$)
{
    my ($self,$attribute) = @_;
    
    #print "Adding attribute: ", $attribute->getName(), "\n";

    $self->{ATTRIBUTES_HASH}->{$attribute->getName()} = $attribute;
    $self->{ATTRIBUTES_LIST}->[$self->{ATTRIBUTES_NUMBER}] = $attribute;
    $self->{ATTRIBUTES_NUMBER}++;
    # print $self->{ATTRIBUTES_NUMBER}, "\n";
}

sub getAttributeList($)
{
    my $self = shift;
    
    return $self->{ATTRIBUTES_LIST};
} 

sub getAttributeByName($$)
{
    my ($self,$name) = @_;
    
    return $self->{ATTRIBUTES_HASH}->{$name}; 
}

sub renameAttribute
  {
    my ($self,$name,$newName) = @_;
    
    my $att = $self->getAttributeByName($name);
    if (defined $att)
      {
	$att->setName($newName);
	delete $self->{ATTRIBUTES_HASH}->{$name};
	$self->{ATTRIBUTES_HASH}->{$newName} = $att;
      }
    else
      {
	print "Dataset does not contain attribute named: $name\n";
      }
  }

sub getAttributeByPos($$)
{
    my ($self,$pos) = @_;
    
    return $self->{ATTRIBUTES_LIST}->[$pos]; 
}

sub getPositionByName($$)
{
    my ($self,$att_search) = @_;
    my ($i,$att_name,@att_list,$found);
    
    @att_list = @{$self->getAttributeList()};
    $i = 0;
    $att_name = $att_list[$i]->getName();
    $found = ($att_name eq $att_search);
    while (($i < $#att_list) && (!$found))
    {
	$i++;
	$att_name = $att_list[$i]->getName(); 
	$found = ($att_name eq $att_search);
    }
    return $i;
}

sub getNumAttributes($)
{ 
    my $self = shift;
    
    return $self->{ATTRIBUTES_NUMBER};
}

# This is a utility. Shouldn't be here but...

sub hasNumericAttributes
  {
    my ($self) = @_;
    
    my ($res);
    $res = 0;
    foreach my $att (@{$self->getAttributeList()})
      {
        if (Durin::Metadata::ATNumber->isNumber($att))
	  {
	    $res = 1;
	    last
	  }
      }
    return $res;
  }

sub convertToIndexes ($$) {
  my ($self,$row) = @_;
  
  my $indexes_row = [];
  my $i = 0;
  foreach my $att (@{$self->getAttributeList()}) {
    push @$indexes_row,$att->getType()->getValuePosition($row->[$i]);
    $i++;
  }
  return $indexes_row;
}

sub convertToValues ($$) {
  my ($self,$indexes_row) = @_;
  
  my $row= [];
  my $i = 0;
  foreach my $att (@{$self->getAttributeList()}) {
    push @$row,$att->getType()->getValue($indexes_row->[$i]);
    $i++;
  }
  return $row;
}
   
sub generateCompleteDataset {
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
  
  $dataset->open();
  do { 
    print "Generated ".join(',',@$row)."\n";
    $dataset->addRow($row);
    my @tmp =  @$row;
    $row = \@tmp;
    $self->increaseAndGenerateObservation($actualValueIndexes,$attTypes,$row);
  } while ($self->stillMoreObservations($actualValueIndexes));
  $dataset->close();
  
  return $dataset;
} 

sub increaseAndGenerateObservation {
  my ($self,$actualValueIndexes,$attTypes,$row)  = @_;
  
  my $actualAttPos = $self->getNumAttributes()-1;
  my $carry = 1;
  while ($carry && ($actualAttPos >= 0)) {
    my $actualValueIndex = $actualValueIndexes->[$actualAttPos];
    if ($actualValueIndex == $attTypes->[$actualAttPos]->getCardinality()-1) {
      $actualValueIndex = 0;
    } else {
      $actualValueIndex++;
      $carry = 0;
    }
    $actualValueIndexes->[$actualAttPos] = $actualValueIndex;
    $row->[$actualAttPos] =  $attTypes->[$actualAttPos]->getValue($actualValueIndex);
    $actualAttPos--;
  }
  if ($carry) {
    $actualValueIndexes->[0] = -1;
  }
}

sub stillMoreObservations {
  my ($self,$actualValueIndexes)  = @_;
  return ($actualValueIndexes->[0] != -1);
}

sub makestring($)
{
    my $self = shift;
    
    my ($i,$string,$tempstring);
    $string = "[ ";
    
    for ($i = 0; $i < ($self->getNumAttributes())-1 ; $i++)
    {
	$tempstring = ($self->getAttributeByPos($i))->makestring();
	$string = $string . $tempstring . " , ";    
    }
    $tempstring = ($self->getAttributeByPos($i))->makestring();
    $string = $string . $tempstring;
    
    return $string . "]";
}

1;
