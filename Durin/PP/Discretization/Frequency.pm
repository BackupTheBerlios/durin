# Implements the equal frequency discretization algorithm
package Durin::PP::Discretization::Frequency;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

#use Durin::Data::MemoryTable;
use Durin::Metadata::ATNumber;

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
    my $numIntervals = $Input->{NUMINTERVALS};
    
    # Get the metadata

    my $schema = $table->getMetadata()->getSchema();
    
    # Create as many arrays as numerical attributes.
    
    my @indexList; # Contains the indexes of the numerical attributes
   
    my @count;
    my $att_no = 0;
    my $indexOnArray = 0;
    foreach  my $att (@{$schema->getAttributeList()})
      {
	if (Durin::Metadata::ATNumber->isNumber($att))
	  {
	    push @indexList,[$att_no,$indexOnArray,$att];
	    push @count,0;
	    $indexOnArray++;
	  }
	$att_no++;
      }
    
    # Fill them up with the values of the attributes.
    
    my @valuesArray;
    my $sub = sub 
      {
	my ($row) = @_;
	
	foreach my $pair (@indexList)
	  {
	    my $val = $row->[$pair->[0]];
	    if (!($pair->[2]->isUnknown($val)))
	      {
		push @{$valuesArray[$pair->[1]]},($val);
		$count[$pair->[1]]++;
	      }
	  }
      }; 
    $table->open();
    $table->applyFunction($sub);
    $table->close();
     
    # Sort them & take the $numIntervals-1 cutpoints equidistantly & construct the discretization
    
    my $i = 0;
    no strict;
    foreach my $array (@valuesArray)
      {
	my @list = sort {$a <=> $b;} @$array;
	$valuesArray[$i] = \@list;
	$i++;
      }
    use strict;
    
    my @attInfoList; # contains pairs [ list of cutpoints, hasUnknowns]
    my $cutPoint;
    foreach my $pair (@indexList)
      {
	my @array = @{$valuesArray[$pair->[1]]};
	my @cutPointList = ();
	
	my $pos = int ($#array / $numIntervals);
	$cutPoint = $array[int ($#array / $numIntervals)];
	if ($cutPoint == $array[0])
	  {
	    my $i = $pos;
	    while ($cutPoint == $array[$i])
	      {
		$i++;
	      }
	    $cutPoint = $array[$i]; 
	  }
	
	push @cutPointList,($cutPoint);
	my $oldoldCutPoint = $array[0];
	my $oldCutPoint = $cutPoint;
	for my $numInt (2..$numIntervals-1)
	  {
	    $cutPoint = $array[int ($numInt * $#array / $numIntervals)];
	    #    print $cutPoint,",";
	    
	    if (($cutPoint != $oldCutPoint) && ($cutPoint!=$oldoldCutPoint))
	      {
		push @cutPointList,($cutPoint);
		$oldoldCutPoint = $oldCutPoint;
		$oldCutPoint = $cutPoint;
	      }
	  }
	push @attInfoList,(\@cutPointList);
	#if ($attInfoRef->[1])
	#  {
	#   print "with unknowns\n";
	# }
	#else
	#  {
	#  print "no unknowns\n";
	#  }
      }
    $self->setOutput(\@attInfoList);
  }

1;

