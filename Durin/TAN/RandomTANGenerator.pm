package Durin::TAN::RandomTANGenerator;

use Durin::ModelGeneration::ModelGenerator;
use Durin::TAN::TAN;
use Durin::ProbClassification::ProbApprox::PATANModel;
use Durin::Classification::ClassedTableSchema;
use Durin::Metadata::Attribute;
use Durin::Metadata::ATCreator;
use Durin::DataStructures::Graph;

use POSIX;

@ISA = qw(Durin::ModelGeneration::ModelGenerator);

use strict;

sub new_delta {
  my ($class,$self) = @_;

  my $self->{NUMBER_OF_ATTRIBUTES_GENERATOR}=sub {return 10;};
  my $self->{NUMBER_OF_VALUES_GENERATOR}=sub {return (rand 5)+1;};
  
}

sub clone_delta {
  my ($class,$self,$source) = @_;
  
  die "Durin::TAN::RandomTANGenerator clone not implemented";
}

sub run($)
{
  my ($self) = @_;
  
  my $input = $self->getInput();
  
  # Get the number of models to generate
  
  if (defined $input->{NUMBER_OF_MODELS}) {
    $self->{NUMBER_OF_MODELS} = $input->{NUMBER_OF_MODELS};
  }

  # Get the number of attributes to generate (including the class)
  
  if (defined $input->{NUMBER_OF_ATTRIBUTES_GENERATOR}) {
    $self->{NUMBER_OF_ATTRIBUTES_GENERATOR} = $input->{NUMBER_OF_ATTRIBUTES_GENERATOR};
  }
  
  # Get the function that generates the number of values per attribute
  
  if (defined $input->{NUMBER_OF_VALUES_GENERATOR}) {
    $self->{NUMBER_OF_VALUES_GENERATOR} = $input->{NUMBER_OF_VALUES_GENERATOR};
  }
  
  # Get the percentage of independent tables 
  
  if (defined $input->{INDEPENDENCE_PERCENTAGE}) {
    $self->{INDEPENDENCE_PERCENTAGE} = $input->{INDEPENDENCE_PERCENTAGE};
  }
    
  my $modelList = [];
  my $model;
  foreach my $i (1..$self->{NUMBER_OF_MODELS}) {
    $model = $self->generateModel($self->{NUMBER_OF_ATTRIBUTES_GENERATOR},
				  $self->{NUMBER_OF_VALUES_GENERATOR},
				  $self->{INDEPENDENCE_PERCENTAGE});
    push @$modelList,$model;
  }
}

sub generateModel {
  my ($self,$attGen,$valGen,$indPct) = @_;

  my $schema = $self->generateSchema($attGen,$valGen);
  my $tree = $self->generateTree($schema);
  my $probApprox = $self->generateProbApprox($schema,$tree,$indPct);
  my $TAN = $self->composeTAN($schema,$probApprox,$tree);

  return $TAN;
}

# Generates the model schema (the attributes & its values)

sub generateSchema {
  my ($self,$attGen,$valGen) = @_;

  my ($att,$attType,$attVals,$attValList);
  my $numAtts = &$attGen();
  my $schema = Durin::Classification::ClassedTableSchema->new();
  foreach my $i (1..$numAtts) {
    $att = Durin::Metadata::Attribute->new(); 
    $att->setName($i);
    $attType = Durin::Metadata::ATCreator->create("Categorical");
    
    $attVals = &$valGen();
    $attValList = $self->generateValList($attVals);
    $attType->setRest(join(':',@$attValList));
    $att->setType($attType);
    $schema->addAttribute($att);
  } 
  # 0 is always the class
  $schema->setClassByPos(0);       ;
  return $schema;
}
  
# Generates the list of values in the "$rest" style 
# of the TSIOStandard format, so it is parsed correctly 
# when it is sent to the attribute type.

sub generateValList {
  my ($self,$numVals) = @_;
  
  my $list = [];
  foreach my $i (1..$numVals) {
    push @$list,$i;
  }
  return $list;
}

# Randomly Generates a tree structure

sub generateTree {
  my ($self,$schema) = @_;
  
  my $Tree = Durin::DataStructures::Graph->new();

  my $attList = $schema->getAttributeList();
  my $numAtts = $schema->getNumAttributes();

  my $sonList = [];
  foreach my $i (1..$numAtts-1) {
    push @$sonList,$i;
  }
  
  # Add $numAtts-2 parent-son links, because one attribute 
  # is the class and another must be the root of the tree 
  foreach my $i (1..$numAtts-2) {
    # Randomly select a son
    my $sonPos = POSIX::floor(rand(scalar(@$sonList)));
    my $son = $sonList->[$sonPos];
    splice(@$sonList,$sonPos,1);
    my $parentFound = 0;
    while (!$parentFound) {
      my $parent = POSIX::floor(rand($numAtts-1)) + 1;
      $parentFound = !$Tree->isAncestor($son,$parent);
      if ($parentFound) {
	$Tree->addEdge($parent,$son,undef);
      }
    }
  }

  return $Tree;
}

sub generateProbApprox {
  my ($self,$schema,$tree,$indPct) = @_;
 
  my $numAtts = $schema->getNumAttributes();
  
  # Calculate the number of independent attributes 

  my $numInd = POSIX::ceil(($numAtts - 1) * $indPct);

  # Calculate the independent attributes

  my $indepSet = {};
  my $att;
  my $i = 0;
  while ($i < $numInd) {
    $att = POSIX::floor(rand($numAtts-1)) + 1;
    if (!defined $indepSet->{$att}) {
      $indepSet->{$att} = 1;
      $i++;
    }
  }

  my $probApprox = Durin::ProbClassification::ProbApprox::PATANModel->new;

  # Generate class probabilities

  my $classPos = $schema->getClassPos();
  my $classAtt = $schema->getAttributeByPos($classPos);
  my $numClasses = $classAtt->getCardinality();
  
  my $distribClass = $self->generateMultinomial($numClasses);
  $probApprox->setDistribution($classPos,$distribClass);
  
  # Generate root probabilities
  # First find the root

  my $node = $tree->getNodes()->[0];
  my $nodeAncestors = $tree->getAncestors($node);
  while (scalar @$nodeAncestors) {
    $node = $nodeAncestors->[0];
    $nodeAncestors = $tree->getAncestors($node);
  }
  my $root = $node;
  my $numValuesRoot = $schema->getAttributeByPos($root)->getCardinality();
  my $distribRootClass;
  if (defined $indepSet->{$root}) {
    my $distribRoot = $self->generateMultinomial($numValuesRoot);
    $distribRootClass = $self->generateIndependentBidimensionalMultinomial($distribClass,$distribRoot); 
  } else {
    $distribRootClass = $self->generateDependentBidimensionalMultinomial($distribClass,$numValuesRoot);
  }
  $probApprox->setDistribution($root,$distribRootClass);

  # Generate probabilities for all the other nodes

  my $distribClassParentNode;
  foreach $node (@{$tree->getNodes()}) {
    if ($node != $root) {
      my $numValuesNode = $schema->getAttributeByPos($node)->getCardinality();	
      my $parent = $tree->getParents($node)->[0];
      my $distribParent = $probApprox->getMarginal($parent);
      if (defined $indepSet->{$node}) {
	my $distribNode = $self->generateMultinomial($numValuesNode);
	$distribClassParentNode = $self->generateIndependentTridimensionalMultinomial($distribClass,$distribParent,$distribNode); 
	$probApprox->setDistribution($node,$distribClassParentNode);
      } else {
	$distribClassParentNode = $self->generateDependentTridimensionalMultinomial($distribClass,$distribParent,$numValuesNode);
      }	
      $probApprox->setDistribution($node,$distribClassParentNode);
    }
  }
}

# Puts all the pieces together

sub composeTAN {
  my ($self,$schema,$probApprox,$tree) = @_;
  
  my $TAN = Durin::TAN::TAN->new();
  $TAN->setSchema($schema);
  $TAN->setProbApprox($probApprox);
  $TAN->setTree($tree);
  
  return $TAN;
}
1;
