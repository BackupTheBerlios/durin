# This class manages a 2-dimensional + class table of counts.

package Durin::ProbClassification::ProbApprox::CountTable;

use Durin::Components::Data;
use PDL;

@ISA = (Durin::Components::Data);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;

    $self->{ORDER} = 2;
    # Contains a map : AttNum->[AttValues -> Integers]  
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::ProbApprox::CountTable clone not implemented";
   
  }

# Sets the number of variable that will be taken into account
sub setOrder
  {
    my ($self,$order) = @_;
    
    $self->{ORDER} = $order;
  }

sub setSchema
  {
    my ($self,$schema) = @_;
    
    # Here we initialize all the counters.

    my $class_attno = ($schema->getClassPos());
    
    $self->{CLASS_ATT_NUMBER} = $class_attno;
    
    my $class_att = $schema->getAttributeByPos($class_attno);
    my $num_classes = scalar (@{$class_att->getType->getValues()});
    
    $self->{NUM_CLASSES} = $num_classes;
    
    my $num_atts = $schema->getNumAttributes();

    $self->{NUM_ATTRIBUTES} = $num_atts;
    
    # For every attribute we create a map from values to integers
    
    $self->{INDEXES} = [];
    foreach my $att (0..$num_atts-1)
      {
	my @att_values = @{$schema->getAttributeByPos($att)->getType()->getValues()};
	my $map = {};
	my $index = 0;
	foreach my $att_val (@att_values)
	  {
	    $map->{$att_val} = $index;
	    $index++;
	  }
	push @{$self->{INDEXES}},$map;
      }
    
    # The general counter
    
    $self->{COUNT} = 0;
    
    # Class counters

    $self->{COUNTCLASS} = zeroes $num_classes;

    # Att x Class pidls

    $self->{COUNTXCLASS} = [];
    foreach my $att (0..$num_atts-1)
      {
	my @att_values = @{$schema->getAttributeByPos($att)->getType()->getValues()};
	my $num_att_values = scalar(@att_values);
	my $array = zeroes $num_att_values,$num_classes;
	push @{$self->{COUNTXCLASS}},$array;
      }
    
    if ($self->{ORDER} > 1)
      {
	# Att x Att x Class pidls
	
	$self->{COUNTXYCLASS} = undef;
	
	foreach my $att1 (0..$num_atts-1)
	  {
	    if ($att1 != $class_attno)
	      {
		my @att_values1 = @{$schema->getAttributeByPos($att1)->getType()->getValues()};
		my $num_att_values1 = scalar(@att_values1);
		foreach my $att2 (0..$att1-1)
		  {
		    if ($att2 != $class_attno)
		      {
			my @att_values2 = @{$schema->getAttributeByPos($att2)->getType()->getValues()};
			my $num_att_values2 = scalar(@att_values2);
			my $array = zeroes $num_att_values1,$num_att_values2,$num_classes;
			$self->{COUNTXYCLASS}->[$att1][$att2] = $array;
		      }
		  }
	      }
	    
	  }
      }
  }
  
sub addObservation
  {
    my ($self,$row) = @_;
    
    my ($class_val,$j,$j_val,$k,$k_val,$j_val_index,$k_val_index);
    
    $self->{COUNT}++;
    #print "I have counted: ", $self->{COUNT}, "\n";
    
    my $class_attno = $self->{CLASS_ATT_NUMBER};
    my $num_atts = $self->{NUM_ATTRIBUTES};
    $class_val = $$row[$class_attno];

    #print "$class_attno,$num_atts,$class_val\n";
    my $class_val_index = $self->{INDEXES}->[$class_attno]->{$class_val};
    #print "$class_attno,$num_atts,$class_val,$class_val_index\n";
    # Increase class counter
    my $pdl = $self->{COUNTCLASS};
    #print "Adding to $class_val_index\n";
    $pdl->set($class_val_index,$pdl->at($class_val_index)+1);
    #$temp++;
    if ($class_attno > $num_atts-1)
      {
	die "Class number is over the last attribute number\n";
      }
    #print "Class = $class_attno\n";
    foreach $j (0..$num_atts-1)
      {
	#print "Attribute $j\n";
	if ($j!=$class_attno)
	  {
	    $j_val = $$row[$j];
	    $j_val_index = $self->{INDEXES}->[$j]->{$j_val};
	    
	    #$temp = $self->{COUNTXCLASS}->[$j]->slice("$j_val_index,$class_val_index");
	    #$temp++;
	    $pdl = $self->{COUNTXCLASS}->[$j];
	    $pdl->set($j_val_index,$class_val_index,$pdl->at($j_val_index,$class_val_index)+1);
	    if ($self->{ORDER} > 1)
	      {
		#print "Order bigger than 1\n";
		foreach $k (0..$j-1)
		  {
		    if ($k!=$class_attno)
		      {
			$k_val = $$row[$k];
			$k_val_index = $self->{INDEXES}->[$k]->{$k_val};
			
			#$pdl = 
			#    $temp = $self->{COUNTXYCLASS}->[$j][$k]->slice("$j_val_index,$k_val_index,$class_val_index");
			#    $temp++;
			#print  "Processing Class val: $class_val  Att1: $j Val1: $j_val Att2: $k Val2: $k_val \n";	
			
			$pdl = $self->{COUNTXYCLASS}->[$j][$k];
			#print "PDL: $pdl\n";
			$pdl->set($j_val_index,$k_val_index,$class_val_index,$pdl->at($j_val_index,$k_val_index,$class_val_index)+1);
		      }
		  }
	      }
	  }
      }
  }

sub getCountClass
  {
    my ($self,$class_val) = @_;
    
    my $class_attno = $self->{CLASS_ATT_NUMBER};
    my $class_val_index = $self->{INDEXES}->[$class_attno]->{$class_val};
    
    #print "$class_val,$class_attno,$class_val_index.\n";
    my $temp = $self->{COUNTCLASS}->at($class_val_index);  
    #print $temp;
    return $temp;
  }

sub getCount
  {
    my ($self) = @_;
    
    return $self->{COUNT};
  }

sub getCountXClass
  {
    my ($self,$class_val,$x,$x_val) = @_;
    
    my $class_attno = $self->{CLASS_ATT_NUMBER};
    my $class_val_index = $self->{INDEXES}->[$class_attno]->{$class_val};
    my $x_val_index = $self->{INDEXES}->[$x]->{$x_val};
    
    my $temp = $self->{COUNTXCLASS}->[$x]->at($x_val_index,$class_val_index);  
    #print $temp;
    return $temp;
  }
  
sub getCountXYClass
  {
    my ($self,$class_val,$x,$x_val,$y,$y_val) = @_;
    
    my $class_attno = $self->{CLASS_ATT_NUMBER};
    my $class_val_index = $self->{INDEXES}->[$class_attno]->{$class_val};
    my $x_val_index = $self->{INDEXES}->[$x]->{$x_val};
    my $y_val_index = $self->{INDEXES}->[$y]->{$y_val};
    
    my $temp = $self->{COUNTXYCLASS}->[$x][$y]->at($x_val_index,$y_val_index,$class_val_index);  
    #print $temp;
    return $temp;
  }

sub getNumClasses
  {
    my ($self) =@_;

    return $self->{NUM_CLASSES};
  }


sub getNumAttValues
  {
    my ($self,$att_no) = @_;

    my $temp =  scalar(keys %{$self->{INDEXES}->[$att_no]});
    #print "$temp\n";
    return $temp;
  }

sub getAttValues
  {
    my ($self,$att_no) = @_;
    
    my @temp =  keys %{$self->{INDEXES}->[$att_no]};
    return \@temp;
  }

sub getClassValues
  {
    my ($self) = @_;
    
    my @temp =  keys %{$self->{INDEXES}->[$self->{CLASS_ATT_NUMBER}]};
    return \@temp;
  }

sub getNumAtts
  {
    my ($self) = @_;
    
    return $self->{NUM_ATTRIBUTES};
  }

sub getClassIndex
  { 
    my ($self) = @_;
    
    return $self->{CLASS_ATT_NUMBER};
  }
