# Constructs the graph with the weigths as described Friedman's paper.

package Durin::TAN::SmoothedGraphConstructor;

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
  
  my ($Graph,$arrayofTablesRef,$schema,$num_atts,$class_attno,$class_att,$info2);
  
  $schema = $self->getInput()->{SCHEMA};
  $arrayofTablesRef = $self->getInput()->{ARRAYOFTABLES};
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
		  $info = $self->calculateSmoothedInf($j,$k,$class_att,$schema,$arrayofTablesRef);
		  $Graph->addEdge($j,$k,$info);
		}
	  }
      }
  }
  $self->setOutput($Graph);
}

sub calculateSmoothedInf
{
  my ($self,$j,$k,$class_att,$schema,$arrayofTablesRef) = @_;

  my (@arrayofTables,$count,%countClass,%countXClass,%countXYClass);
  
  @arrayofTables = @$arrayofTablesRef;
  $count = ${$arrayofTables[0]};
%countClass = %{$arrayofTables[1]};
  %countXClass = %{$arrayofTables[2]};
  %countXYClass = %{$arrayofTables[3]};
  
  my ($class_val,@class_values,@j_values,$j_val,@k_values,$k_val);
  my ($Cxyz,$Cz,$Cxz,$Cyz,$Pxyz,$quotient,$temp,$infoTotal,$card_j,$card_k,$card_class);
  
  @class_values = @{$class_att->getType()->getValues()};
  @j_values = @{$schema->getAttributeByPos($j)->getType()->getValues()};
  @k_values = @{$schema->getAttributeByPos($k)->getType()->getValues()};
  $card_j = $#j_values + 1;
  $card_k = $#k_values + 1;
  $card_class = $#class_values + 1;
  $infoTotal = 0.0;
  foreach $class_val (@class_values)
    {	
      foreach $j_val (@j_values)
	{
	  foreach $k_val (@k_values)
	    {
	      # print "$count\n";
	      $Cxyz = $countXYClass{$class_val}[$j]{$j_val}[$k]{$k_val};
	      $Cz = $countClass{$class_val};
	      $Cxz = $countXClass{$class_val}[$j]{$j_val};
	      $Cyz = $countXClass{$class_val}[$k]{$k_val};

	      $quotient = ((($Cxyz + 1) * ($Cz + $card_j * $card_k)) / (($Cxz + $card_k) * ($Cyz + $card_j)));
	      $Pxyz = ($Cxyz + 1) / ($count + $card_j * $card_k * $card_class);;
	      $temp = $Pxyz * log($quotient) / log(2);
	      $infoTotal += $temp;
	    }
	}
    }
  #print "Info ($j,$k) = $infoTotal\n";
  return $infoTotal;
}

1;
