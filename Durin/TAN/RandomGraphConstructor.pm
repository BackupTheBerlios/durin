# Constructs the graph with the weigths as described Friedman's paper.

package Durin::TAN::RandomGraphConstructor;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::DataStructures::UGraph;

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
  
  my ($Graph,$arrayofTablesRef,$schema,$num_atts,$class_attno,$class_att,$info2,$PA);
  
  $schema = $self->getInput()->{SCHEMA};
  #$arrayofTablesRef = $self->getInput()->{ARRAYOFTABLES};
  #$PA = $self->getInput()->{PROBAPPROX};
  $Graph = Durin::DataStructures::UGraph->new();


  $class_attno = ($schema->getClassPos());
  $class_att = $schema->getAttributeByPos($class_attno);
  $num_atts = $schema->getNumAttributes();
  
  my ($j,$k,$info);
  
  foreach $j (0..$num_atts-1)
  {
    if ($j!=$class_attno)
      {
	  foreach $k (0..$j-1)
	    {
	      if ($k!=$class_attno)
		{
		  #$info = $self->calculateInf($j,$k,$class_att,$schema,$PA);
		  # $info2 = $self->calculateSmoothedInf($j,$k,$class_att,$schema,$arrayofTablesRef);
		  # print "Info($j,$k): without smoothing p's: $info with smoothing:$info2\n";
		  $Graph->addEdge($j,$k,rand 1);
	      }
	  }
      }
  }
  $self->setOutput($Graph);
}

sub calculateInf
{
  my ($self,$j,$k,$class_att,$schema,$PA) = @_;

  #my (@arrayofTables,$count,%countClass,%countXClass,%countXYClass);
  
  #@arrayofTables = @$arrayofTablesRef;
  #$count = ${$arrayofTables[0]};
  #%countClass = %{$arrayofTables[1]};
  #%countXClass = %{$arrayofTables[2]};
  #%countXYClass = %{$arrayofTables[3]};

  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  my ($Pxyz,$Pz,$Pxz,$Pyz,$quotient,$temp,$infoTotal,$infoPartial);

  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  
  $infoTotal = 0.0;

  foreach $class_val (@class_values)
  {	
      foreach $j_val (@j_values)
	{
	  foreach $k_val (@k_values)
	    {
	      #$Pxyz = $countXYClass{$class_val}[$j]{$j_val}[$k]{$k_val};
	      #$Pz = $countClass{$class_val};
	      #$Pxz = $countXClass{$class_val}[$j]{$j_val};
	      #$Pyz = $countXClass{$class_val}[$k]{$k_val};
	      #if ($Pxyz!=0)
		#(($Pxyz!=0) && ($Pxz != 0) && ($Pyz != 0) && ($Pz!=0))
	      #	{
		#  $quotient = ($Pxyz * $Pz) / ($Pxz * $Pyz);
		#  $temp = $Pxyz * log($quotient) / ($count * log(2));
		#}
	      #else
	#	{
	#	  $temp = 0;
	#	}
	      
	      
	      $Pxyz = $PA->getPXYClass($class_val,$j,$j_val,$k,$k_val);
	      if ($Pxyz != 0)
		{
		  $infoPartial = $Pxyz * log($PA->getSinergy($class_val,$j,$j_val,$k,$k_val)) / log(2);
		}
	      else
		{
		  $infoPartial = 0;
		}
	      $infoTotal += $infoPartial;
	    }
	}
    }
#print "Info ($j,$k) = $infoTotal\n";
  return $infoTotal;

}

1;
