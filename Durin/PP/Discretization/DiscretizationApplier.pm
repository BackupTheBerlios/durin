
package Durin::PP::Discretization::DiscretizationApplier;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

#use Durin::Data::MemoryTable;
use Durin::Data::FileTable;
use Durin::Metadata::ATNumber;
use Durin::Metadata::ATCreator;

sub new_delta
  {
    my ($class,$self) = @_;
    
    #   $self->{METADATA} = undef; 
}

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub run
  {
    my ($self) = @_;
    
    my $Input = $self->getInput();
    my $table = $Input->{TABLE};
    my $disc = $Input->{DISC};
    my $newTable;
    
    #print "Executing DA\n";

    if (exists $Input->{OUTPUT_TABLE})
      {
	#print "Taking the table\n";
	$newTable = $Input->{OUTPUT_TABLE};
      }
    else
      {
	#print "Creating the table\n";
	$newTable = Durin::Data::FileTable->new();
      }
    
    #foreach my $pair (@$disc)
    #  {
#	foreach my $cutPoint (@{$pair->[0]})
	#  {
	#print $cutPoint,",";
      #}
#	if ($pair->[1])
	#  {
	#    print "with uunknowns\n";
	#  }
	#else
	#  {
	#    print "no uunknowns\n";
	#  }
     # }
    #print "I printed it two times\n";
    # Get the metadata

    my $metadata;
    
    if (defined $newTable->getMetadata())
      {
	$metadata = $newTable->getMetadata();
	#print "Taking the metadata\n";
	if (!defined $metadata->getName())
	  {
	    $metadata->setName("D".$table->getMetadata()->getName());
	  }
      }
    else
      {
	#print "MD = ",$table->getMetadata()."\n";
        $metadata = $table->getMetadata()->new();
	#print "Creating the metadata",$table->getMetadata()->getName()," \n";
	$metadata->setName("D".$table->getMetadata()->getName());
      }
    
    my $schema = $table->getMetadata()->getSchema();
    
    my $newSchema;
    if (defined $metadata->getSchema())
      {
	$newSchema = $metadata->getSchema();
	#print "Taking the schema\n";
	#$newSchema->getMetadata()->getOutExtInfo()->makestring();
      }
    else
      {
	$newSchema = $schema->new();
	#print "Creating the schema\n";
      }
    
    # Generate the metadata for the new table
    
    # We generate the new schema using the other schema as prototype
    
    my @attList;
    my $posInList = 0;
    my $posInSchema = 0;
    
    foreach  my $att (@{$schema->getAttributeList()})
      {
	if (Durin::Metadata::ATNumber->isNumber($att))
	  {
	    # If the attribute is a number we create the discrete one
	    
	  #  print "Is numbar\n";
	    my $newAtt = $att->new();
	    my $attType = Durin::Metadata::ATCreator->create("Categorical");
	    my @cutPointList = @{$disc->[$posInList]};
	    my @values;
	    
	    if ($#cutPointList >= 0)
	      {
		my $previousCutPoint = $cutPointList[0];
		$values[0] = "A0. <".$previousCutPoint;
		my $i = 1;
		while ($i <= $#cutPointList)
		  {
		    $values[$i] = "A$i".". ".$previousCutPoint."-".$cutPointList[$i];
		    $previousCutPoint = $cutPointList[$i];
		    $i++;
		  }
		$values[$i] = "A$i. >=".$previousCutPoint;
		
		# If the attribute has unknown values we add the question mark
		
		if ($att->getType()->getHasUnknowns())
		  {
		    $i++;
		    $values[$i] = $attType->unknownValue();
		  }
	      }
	    else
	      {
		$values[0] = "NonDiscriminant";
	      }
	    $cutPointList[0] = -exp(200);
	    #print join(",",@values),"\n";
	    $attType->setValues(\@values);
	    $newAtt->setType($attType);
	    $newAtt->setName("D".$att->getName());
	    push @attList,([$posInList,$posInSchema,$newAtt]);
	    $newSchema->addAttribute($newAtt);
	    $posInList++;
	  }
	else
	  {
	#    print "Is not numbar\n";
	    # Otherwise we just copy it.
	    $newSchema->addAttribute($att->clone());
	  }
	$posInSchema++;
      }
    $newSchema->setClassByPos($schema->getClassPos());
   
    $metadata->setSchema($newSchema);
   
    $newTable->setMetadata($metadata);
    $newTable->open(">");
    $table->open("<");
    $table->applyFunction(sub
			  {
			    my ($row) = @_;
			    
			    my @newRow = @$row;
			    foreach my $pair (@attList)
			      {
				my $posInList = $pair->[0];
				my $posInSchema = $pair->[1];
				my $att = $pair->[2];
				$newRow[$posInSchema] = discretizeValue($row->[$posInSchema],
									$att,
									$disc->[$posInList],
									$att->getType()->getValues());
			      }
			    $newTable->addRow(\@newRow);
			  }
			 );
    $table->close();
    $newTable->close();

    $self->setOutput($newTable);
  }

sub discretizeValue
  {
    my ($value,$att,$cutPointList,$valueList) = @_;
    
    #print "Value is $value ";
    if ($att->isUnknown($value))
      {
	#print "and is unknown\n";
	# if it is unknown we return it as it is
	return $value;
      }
    else
      {
	my $i = 0;
	foreach my $cutPoint (@$cutPointList)
	  {
	    last if ($value < $cutPoint); 
	    $i++;
	  }
	#print "and the label is [$i]: ",$valueList->[$i],"\n"; 
	return $valueList->[$i];
      }
  }

    



1;
