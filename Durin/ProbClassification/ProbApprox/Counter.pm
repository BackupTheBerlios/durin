package Durin::ProbClassification::ProbApprox::Counter;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

#use Durin::Data::MemoryTable;
use Durin::ProbClassification::ProbApprox::CountTable;

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

sub run($)
{
  my ($self) = @_;
  
  my ($table,$schema,$count,%countClass,%countXClass,%countXYClass,$class_att,$class_attno,$num_atts,@countTables);
  
  print "Started counting\n";
  $table = $self->getInput()->{TABLE};
  my $order = 2;
  if (exists $self->getInput()->{ORDER})
    {
      $order = $self->getInput()->{ORDER};
    }
  $schema = $table->getSchema(); #It is supposed to be a ClassedTableSchema
  
  my $countTable = Durin::ProbClassification::ProbApprox::CountTable->new();
  $countTable->setOrder($order);
  $countTable->setSchema($schema);
  
#  print "Init step finished \n";
  my($obs) = 0;
  $table->open();
  $table->applyFunction(sub 
			{
			  $countTable->addObservation(@_);
			});
  
  $table->close();
  # print "Counting step finished \n";
  #$self->printCountTable(\%countTable,$schema,$class_attno,$class_att,$num_atts);
  #print "I have counted: $count\n";
  
  $self->setOutput($countTable);
  print "Finished counting\n";
}

sub initCountTables($$$$$$)
{		    
  my ($self,$schema,$class_attno,$class_att,$num_atts) = @_;

  #print "Class Att Num: $class_attno \n";
  #print "Class Att: $class_att \n";
  my ($count,%countClass,%countXClass,%countXYClass,$class_val,@class_values,$j,@j_values,$j_val,$k,@k_values,$k_val);
  

  $count = 0;
  @class_values = @{$class_att->getType()->getValues()};
  foreach $class_val (@class_values)
    {		
      $countClass{$class_val} = 0;	
      #print "Processing Class val: $class_val \n";
      foreach $j (0..$num_atts-1)
	{
	  if ($j!=$class_attno)
	    {
		#print  "Processing Class val: $class_val, Att1: $j \n";
	      @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
	      foreach $j_val (@j_values)
		{
		  $countXClass{$class_val}[$j]{$j_val} = 0;
		  
		  #print  "Processing Class val: $class_val, Att1: $j Val1: $j_val\n";
		  foreach $k (0..$j-1)
		    {
		      if ($k!=$class_attno)
			{
			  #print  "Processing Class val: $class_val  Att1: $j Val1: $j_val Att2: $k \n";
			  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
			  foreach $k_val (@k_values)
			    {
				#print  "Processing Class val: $class_val  Att1: $j Val1: $j_val Att2: $k Val2: $k_val \n";	
				$countXYClass{$class_val}[$j]{$j_val}[$k]{$k_val}=0;
			      }
			}
		    }
		}
	    }
	}
    }
  return [\$count,\%countClass,\%countXClass,\%countXYClass];
}

sub printCountTable($$$$$$)
{		    
  my ($self,$countTableRef,$schema,$class_attno,$class_att,$num_atts) = @_;

  #print "Class Att Num: $class_attno \n";
  #print "Class Att: $class_att \n";
  my (%countTable,$class_val,@class_values,$j,@j_values,$j_val,$k,@k_values,$k_val);
  
  %countTable = %$countTableRef;
  @class_values = @{$class_att->getType()->getValues()};
  foreach $class_val (@class_values)
    {	
      #print "Processing Class val: $class_val \n";
      foreach $j (1..$num_atts-1)
	{
	  if ($j!=$class_attno)
	    {
		#print  "Processing Class val: $class_val, Att1: $j \n";
	      @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
	      foreach $j_val (@j_values)
		{
		  	
 #print  "Processing Class val: $class_val, Att1: $j Val1: $j_val\n";
		  foreach $k (1..$j-1)
		    {
		      if ($k!=$class_attno)
			{
			  #print  "Processing Class val: $class_val  Att1: $j Val1: $j_val Att2: $k \n";
			  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
			  foreach $k_val (@k_values)
			    {
			      print  "Observations of class: $class_val  Att1: $j Val1: $j_val Att2: $k Val2: $k_val  ==  ", $countTable{$class_val}[$j]{$j_val}[$k]{$k_val},"\n";
			    }
			}
		    }
		}
	    }
	}
    }
}

1;
