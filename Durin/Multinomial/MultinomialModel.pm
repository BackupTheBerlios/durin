package Durin::Multinomial::MultinomialModel;

use Class::MethodMaker get_set => [-java => qw/ Distribution Schema/];

use strict;
use warnings;

use Durin::Classification::Model;

@Durin::Multinomial::MultinomialModel::ISA =  qw(Durin::Classification::Model);

use Durin::Data::MemoryTable;


sub new_delta
{
  my ($class,$self) = @_;
  
  $self->{TREE} = undef;
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::TAN::TAN clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
}


sub getP {
  my ($self,$row)  = @_;

  my $schema = $self->getSchema();
  my $indexes_row = $schema->convertToIndexes($row);
  my $thisP =  $self->getDistribution()->getP($indexes_row);
  #print "P(".join(',',@$row).") = $thisP\n";
  return $thisP;
}
    
sub predict {
  my ($self,$row_to_classify) = @_;
  
  my $schema = $self->getSchema();
  my $classPos = $schema->getClassPos();
  my $classAtt = $schema->getAttributeByPos($classPos);
  my $maxP = -1;
  my $maxClass;
  my $thisP;
  my $distrib = {};
  my $total = 0;
  for my $val (@{$classAtt->getType()->getValues()}) {
    $row_to_classify->[$classPos] = $val;
    $thisP = $self->getP($row_to_classify);
    $distrib->{$val} = $thisP;
    if ($thisP >= $maxP) {
      $maxP = $thisP;
      $maxClass = $val;
    }
    $total += $thisP;
  }
  for my $val (@{$classAtt->getType()->getValues()}) {
    $distrib->{$val} /= $total;
  }
  
  return [$distrib,$maxClass];
}

sub classify
  {
    my ($self,$row_to_classify) = @_;
    
    my ($distrib,$class) = @{$self->predict($row_to_classify)};
    
    return $class;
  }

sub generateObservation {
  my ($self) = @_;
  
  my $indexes_row = $self->getDistribution()->sample();
  #print "Indexes: ".join(',',@$indexes_row)."\n";
  my $row = $self->getSchema()->convertToValues($indexes_row);
  print join(',',@$row)."\n";
  return $row;
}

