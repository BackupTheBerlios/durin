package Durin::ProbClassification::BMA;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

sub new_delta
{
  my ($class,$self) = @_;
  
  $self->{WEIGHTEDMODELLIST} = (); 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::BMA clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
}

sub addWeightedModel
{
    my ($self,$model,$weight) = @_;
    
    push @{$self->{WEIGHTEDMODELLIST}},([$model,$weight]);
}

sub getWeightedModelList
{
    my ($self) = @_;

    return $self->{WEIGHTEDMODELLIST}
}

sub setWeightedModelList
{
    my ($self,$list) = @_;

    $self->{WEIGHTEDMODELLIST} = $list;
}

sub normalizeWeights
{
    my ($self) = @_;

    my ($pair,$sum,@newList);
    $sum = 0;
    @newList = ();
    foreach $pair (@{$self->getWeightedModelList()})
    {
	$sum += ($pair->[1]);
    }
    foreach $pair (@{$self->getWeightedModelList()})
    {
      push @newList,([$pair->[0],($pair->[1])/$sum]);
    }
    $self->setWeightedModelList(\@newList);
  }

sub predict
{
    my ($self,$row_to_classify) = @_;
    
    my ($schema,$class_attno,$class_att,@class_values,%Prob,$ProbTemp,$value);

    $schema = $self->getSchema();
    $class_attno = $schema->getClassPos();
    $class_att = $schema->getAttributeByPos($class_attno);
    @class_values = @{$class_att->getType()->getValues()};
    foreach $value (@class_values)
    {
	$Prob{$value} = 0;
    }
    
    foreach my $pair (@{$self->{WEIGHTEDMODELLIST}})
      {
	my $model = $pair->[0];
	my $weight = $pair->[1];
	$ProbTemp = $model->predict($row_to_classify)->[0];	
	foreach $value (@class_values)
	  {
	    $Prob{$value} += ($ProbTemp->{$value} * $weight);
	  }
      }
    
    my $sum = 0.0; 
    my $max;
    my $probMax = 0.0;
    foreach $value (@class_values)
      {
	if ($probMax <= $Prob{$value})
	  {
	    $probMax = $Prob{$value};
	    $max = $value;
	  }
	$sum += $Prob{$value};
      }
    foreach $value (@class_values)
      {
	$Prob{$value} = $Prob{$value} / $sum;
      }
    return ([\%Prob,$max]);
}   


sub classify
{
    my ($self,$row_to_classify) = @_;
    
    my $ProbRef = $self->predict($row_to_classify);
    
    my (@class_values,$class_val,$Max,$ProbMax);
    
    @class_values = @{$self->getSchema()->getAttributeByPos($self->getSchema()->getClassPos())->getType()->getValues()};
    
    $Max = 0;
    $ProbMax = 0;
    foreach $class_val (@class_values)
    {
	if ($ProbMax <= $ProbRef->{$class_val})
	{
	    $ProbMax = $ProbRef->{$class_val};
	    $Max = $class_val;
	}
    }
    return $Max;
}
