# Implements the equal frequency discretization algorithm
package Durin::PP::Discretization::FayyadIrani;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::DataStructures::ContingencyTable;
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

    # Get the metadata

    my $schema = $table->getMetadata()->getSchema();
    my $classAttNumber = $schema->getClassPos();
    my @classValues = @{$schema->getAttributeByPos($classAttNumber)->getType()->getValues()};

    # Create as many arrays as numerical attributes.
    
    my @indexList; # Contains the indexes of the numerical attributes
   
    my @count;
    my $att_no = 0;
    my $indexOnArray = 0;
    foreach  my $att (@{$schema->getAttributeList()})
      {
	if (Durin::Metadata::ATNumber->isNumber($att))
	  {
	    push @indexList,([$att_no,$indexOnArray,$att]);
	    push @count,(0);
	    $indexOnArray++;
	  }
	$att_no++;
      }

    # Initialize class counters
    
    my %classCounter;
    foreach my $possibleClassVal (@classValues)
      {
	$classCounter{$possibleClassVal} = 0;
      }
   
    # Fill them valuesArray with the values of the attributes, taking care of repetitions.
    
    my @valuesArray;
    my $sub = sub 
      {
	my ($row) = @_;
	
	my $classVal = $row->[$classAttNumber];
	$classCounter{$classVal}++;
	foreach my $pair (@indexList)
	  {
	    my $val = $row->[$pair->[0]];
	    # print "$val\n";
	    if (!($pair->[2]->isUnknown($val)))
	      {
		if (exists $valuesArray[$pair->[1]]{$val})
		  {
		    $valuesArray[$pair->[1]]{$val}[0]++;
		    $valuesArray[$pair->[1]]{$val}[1]{$classVal}++;
		  }
		else
		  {
		    $valuesArray[$pair->[1]]->{$val}[0] = 1;
		    foreach my $possibleClassVal (@classValues)
		      {
			$valuesArray[$pair->[1]]->{$val}->[1]->{$possibleClassVal} = 0;
		      }
		    $valuesArray[$pair->[1]]{$val}[1]{$classVal}++;
		  }		#push @{$valuesArray[$pair->[1]]},($val);
		$count[$pair->[1]]++;
	      }
	  }
      }; 
    $table->open();
    $table->applyFunction($sub);
    $table->close();
     
   
    #my @sortedValuesArray; 
    
    my @attInfoList;

    # For each attribute:
   
    foreach my $hash (@valuesArray)
      {
	 # We sort the different values
    
	my @list = keys %$hash;
	#print (join(",",@list),"\n");
	no strict;
	@list = sort {$a <=> $b;} @list ;  
	use strict;

	#print (join(",",@list),"\n");

	my @CTArray;
	
	# Calculate the Contingency tables for each cutpoint
	
	my $FirstValue = $list[0];
	my $i = 0;
	
	# 1. Initialize 
	my $newCT = Durin::DataStructures::ContingencyTable->new();
	
	foreach my $possibleClassValue (@classValues)
	  {
	    $newCT->set(0,$possibleClassValue,$hash->{$FirstValue}[1]{$possibleClassValue});
	    $newCT->set(1,$possibleClassValue,$classCounter{$possibleClassValue} - $hash->{$FirstValue}[1]{$possibleClassValue});
	  }
	$CTArray[$i] = $newCT;
	my $previousCT = $newCT;

	# 3. For each cutpoint

	for ($i = 1; $i < $#list ; $i++)
	  {
	    my $value = $list[$i];
	    # We Calculate its CT. Cutpoint = [$PreviousValue + $value / 2]  
	    my $newCT = Durin::DataStructures::ContingencyTable->new();
	    
	    foreach my $possibleClassValue (@classValues)
	      {
		$newCT->set(0,$possibleClassValue,$previousCT->get(0,$possibleClassValue) + $hash->{$value}[1]{$possibleClassValue});
		$newCT->set(1,$possibleClassValue,$previousCT->get(1,$possibleClassValue) - $hash->{$value}[1]{$possibleClassValue});
	      }
	    $previousCT = $newCT;
	    $CTArray[$i] = $newCT;
	  }
	
	#while there are intervals left
	# {
	#     take next interval
	#     calculate the best cutpoint
	#     if the cutpoint is significant 
	#     {
	#         add cutpoint to discretization 
        #         insert two new intervals 
	#     }
	# }

	my @cutPointList = ();
	my @intervalList = ([0,$#CTArray]);
	my $isFirstCutPoint = 1;
	while ($#intervalList >= 0)
	  {
	    my $interval = pop @intervalList;
	    my $first = $interval->[0];
	    my $last = $interval->[1];
	    print "Analyzing interval: [$first,$last]\n";
	    if ($first != $last)
	      {
		my $minEntropy = $CTArray[$first]->getEntropyX();
		my $i = $first + 1; 
		my $minCP = $first;
		while ($i <= $last)
		  {
		    my $thisEntropy = $CTArray[$i]->getEntropyX();
		    #print "Entropy: $thisEntropy\n";
		    if ($thisEntropy < $minEntropy)
		      {
			$minEntropy = $thisEntropy;
			$minCP = $i;
		      }
		    $i++;
		  }
		
		if ($CTArray[$minCP]->isSignificant() || $isFirstCutPoint)
		  {
		    $isFirstCutPoint = 0;
		    # add the cutpoint
		    push @cutPointList,(($list[$minCP] + $list[$minCP + 1]) / 2);	
		    # add the new intervals to be considered in the future
		
		    if ($last == $minCP)
		      {
			push @intervalList,([$first,$minCP-1]);
		      }
		    else
		      {
			if ($first == $minCP)
			  {
			    push @intervalList,([$minCP+1,$last]); 
			  }
			else
			  {
			    push @intervalList,([$first,$minCP-1],[$minCP+1,$last]); 
			  }
		      }

		    
		    # copy the contingency table of the cutpoint
		    
		    my $CPCT = $CTArray[$minCP]->clone();
		    #print "CPCT\n";
		    #$CPCT->print();
		    #foreach my $possibleClassValue (@classValues)
		    #  {
		    #    $CPCT[0]{$possibleClassValue} = $CPCT[$minCP][0]{$possibleClassValue};  
		    #    $CPCT[1]{$possibleClassValue} = $CPCT[$minCP][1]{$possibleClassValue};
		    #  }
		    # modify the contingency tables
		    
		    my $j;
		    for ($j = $first ; $j <= $minCP; $j++)
		      {
			my $CT = $CTArray[$j];
			#$CT->print();
			foreach my $possibleClassValue (@classValues)
			  {
			    $CT->set(1,$possibleClassValue,$CT->get(1,$possibleClassValue) - $CPCT->get(1,$possibleClassValue));
			  }
		      }
		    for ($j = $minCP+1 ; $j <= $last; $j++)
		      {
			my $CT = $CTArray[$j];
			foreach my $possibleClassValue (@classValues)
			  {
			    $CT->set(0,$possibleClassValue,$CT->get(0,$possibleClassValue) - $CPCT->get(0,$possibleClassValue));
			  }
		      }
		  }
	      }
	  }
	push @attInfoList,(\@cutPointList);
      } 
    $self->setOutput(\@attInfoList);
  }

1;

