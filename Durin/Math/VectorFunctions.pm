package Durin::Math::VectorFunctions;

use strict;

sub CalculateRelativeChangeVector
  {
    my ($vector) = @_;
    
    my $previous = $vector->[0];
    my ($actual,$dif,$sum,$weightedDif);
    my $RCV = [];
    for (my $i = 1 ; $i < scalar(@$vector); $i++)
      {
	$actual = $vector->[$i];
	#print "Actual = $actual Previous=$previous\n";
	$dif = $actual - $previous;
	$sum = $actual + $previous;
	if ($sum)
	  {
	    $weightedDif = $dif/$sum;
	  }
	else 
	  {
	    $weightedDif = 0;
	  }
	#print "i = $i Dif = $dif, Sum = $sum, WeightedDif=$weightedDif\n";
	push @$RCV,$weightedDif;
	$previous = $actual;
      }
    #print "Vector: ".join(",",@$vector)."\n";
    #print "Difference vector: ".join(",",@$RCV)."\n";

    return $RCV;
  }

# the same as calculateRelativeChangeVector but for a set of vectors;

sub GroupCalculateRelativeChangeVector
  {
    my ($vectorSet) = @_;
    
    my $outputVectorSet = undef;
    if (ref($vectorSet) eq "ARRAY")
      {
        $outputVectorSet = [];
	foreach my $vector (@$vectorSet)
	  {
	    push @$outputVectorSet,CalculateRelativeChangeVector($vector);
	  }
      }
    else
      {
	if (ref($vectorSet) eq "HASH")
	  {
	    $outputVectorSet = {};
	    foreach my $vectorIndex (keys %$vectorSet)
	      {
		$outputVectorSet->{$vectorIndex} = CalculateRelativeChangeVector($vectorSet->{$vectorIndex});
	      }
	  }
	else
	  {
	    die "Representation for set unknown at Durin::Math::VectorFunctions::GroupCalculateRelativeChangeVector\n";
	  }
      }
    return $outputVectorSet;
  }

# Applies a function to each element of a vector

sub VectorApply
  {
    my ($function,$vector) = @_;

    my $newVector = [];
    foreach my $val (@$vector)
      {
	push @$newVector,&$function($val);
      }
    return $newVector;
  }

# Applies a function to a set of vectors
sub GroupApply
  {
    my ($function,$vectorSet) = @_;
    
    my $outputVectorSet = undef;
    if (ref($vectorSet) eq "ARRAY")
      {
        $outputVectorSet = [];
	foreach my $vector (@$vectorSet)
	  {
	    push @$outputVectorSet,VectorApply($function,$vector);
	  }
      }
    else
      {
	if (ref($vectorSet) eq "HASH")
	  {
	    $outputVectorSet = {};
	    foreach my $vectorIndex (keys %$vectorSet)
	      {
		$outputVectorSet->{$vectorIndex} = VectorApply($function,$vectorSet->{$vectorIndex});
	      }
	  }
	else
	  {
	    die "Representation for set unknown at Durin::Math::VectorFunctions::GroupCalculateRelativeChangeVector\n";
	  }
      }
    return $outputVectorSet;
  }  
    
    1;
