package Durin::TAN::RandomTANGenerator;

@ISA = qw(Durin::ModelGeneration::ModelGenerator);
use Class::MethodMaker get_set => [-java => qw/ Schema MultinomialGenerator IndepSet ProbApprox Tree TAN/];

use strict;
use warnings;

use Durin::TAN::TAN;
use Durin::Math::Prob::MultinomialGenerator;
use Durin::ProbClassification::ProbApprox::PATANModel;
use Durin::Classification::ClassedTableSchema;
#use Durin::Metadata::Attribute;
#use Durin::Metadata::AttributeType;
#use Durin::Metadata::ATCreator;
#use Durin::Metadata::Attribute;
#use Durin::Metadata::AttributeType;
use Durin::DataStructures::Graph;

use POSIX;


sub new_delta {
  my ($class,$self) = @_;
  
  $self->{INDEPENDENCE_PERCENTAGE} = 0;
  $self->setMultinomialGenerator(Durin::Math::Prob::MultinomialGenerator->new());
    
}

sub clone_delta {
  my ($class,$self,$source) = @_;
  
  die "Durin::TAN::RandomTANGenerator clone not implemented";
}

sub init($$) {
  my ($self,$input) = @_;

  $self->SUPER::init($input);
  
  # Get the percentage of independent tables 
  
  if (defined $input->{INDEPENDENCE_PERCENTAGE}) {
    $self->{INDEPENDENCE_PERCENTAGE} = $input->{INDEPENDENCE_PERCENTAGE};
  }
}


sub generateModel {
  my ($self) = @_;

  $self->generateSchema();
  $self->generateTree();
  $self->generateProbApprox();
  $self->composeTAN();

  return $self->getTAN();
}


# Randomly Generates a tree structure

sub generateTree {
  my ($self) = @_;

  my $schema = $self->getSchema();
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
      $parentFound = (!$Tree->isAncestor($son,$parent) && !($son==$parent));
      if ($parentFound) {
	$Tree->addEdge($parent,$son,undef);
	print "adding $parent->$son \n";
      }
    }
  }
  $self->setTree($Tree);
}

sub generateProbApprox {
  my ($self) = @_;
 
  my $indPct = $self->{INDEPENDENCE_PERCENTAGE};
  my $schema = $self->getSchema();
  my $tree = $self->getTree();
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
  $self->setIndepSet($indepSet);
  
  my $probApprox = Durin::ProbClassification::ProbApprox::PATANModel->new();
  $probApprox->setSchema($schema);
  $self->setProbApprox($probApprox);
  # Generate class probabilities

  my $classPos = $schema->getClassPos();
  my $classAtt = $schema->getAttributeByPos($classPos);
  my $numClasses = $classAtt->getType()->getCardinality();
  
  my $distribClass =  $self->getMultinomialGenerator()->generateUnidimensionalMultinomial($numClasses);
  $probApprox->setDistribution($classPos,$distribClass);
  
  # First find the root

  #my $node = $tree->getNodes()->[0];
  my $root = $tree->getRoot();
  print "Root: $root\n";
  # Generate probabilities for all the nodes starting by the root downwards
  
  $self->recursivelyGenerateDistributions($root);
}

sub recursivelyGenerateDistributions {
  my ($self,$node) = @_;
  
  # Generate distribution for this node
  $self->generateDistribution($node);
  
  my $tree = $self->getTree();
  my $sons = $tree->getSons($node);
  print "Sons: ".join(',',@$sons)."\n";
  foreach my $son (@$sons) {
    $self->recursivelyGenerateDistributions($son);
  }
}
  

sub generateDistribution {
  my ($self,$node) = @_;

  print "Generating CPT for node $node\n";
  my $tree = $self->getTree();
  my $parents = $tree->getParents($node);
  my $numParents = scalar @$parents;
  my $schema = $self->getSchema();
  my $multinomialGenerator = $self->getMultinomialGenerator();
  my $probApprox = $self->getProbApprox();
  my $distribClass = $probApprox->getDistribution($schema->getClassPos());
  my $indepSet = $self->getIndepSet();
  if ($numParents == 0) {
    # We are in the root
    #my $root = $node;
    my $numValuesRoot = $schema->getAttributeByPos($node)->getType()->getCardinality();
    my $distribRootClass;
    if (defined $indepSet->{$node}) {
      print "Generating Independent distribution\n";
      my $distribRoot = $multinomialGenerator->generateUnidimensionalMultinomial($numValuesRoot);
      $distribRootClass = $multinomialGenerator->generateIndependentBidimensionalMultinomial($distribClass,$distribRoot); 
    } else {
      print "Generating Dependent distribution\n";
      $distribRootClass = $multinomialGenerator->generateDependentBidimensionalMultinomial($distribClass,$numValuesRoot);
    }
    $probApprox->setDistribution($node,$distribRootClass);
  } else {
    my $distribClassParentNode;
    my $numValuesNode = $schema->getAttributeByPos($node)->getType()->getCardinality();	
    my $parent = $tree->getParents($node)->[0];
    my $distribParent = $probApprox->getMarginalDistribution($parent);
    if (defined $indepSet->{$node}) { 
      print "Generating Independent distribution\n";
      my $distribNode = $multinomialGenerator->generateUnidimensionalMultinomial($numValuesNode);
      $distribClassParentNode = $multinomialGenerator->generateIndependentTridimensionalMultinomial($distribClass,$distribParent,$distribNode); 
    } else { 
      print "Generating Dependent distribution\n";
      $distribClassParentNode = $multinomialGenerator->generateDependentTridimensionalMultinomial($distribClass,$distribParent,$numValuesNode);
    } 
    $probApprox->setDistribution($node,$distribClassParentNode);
  }
}

# Puts all the pieces together

sub composeTAN {
  my ($self) = @_;
  
  my $TAN = Durin::TAN::TAN->new();
  $TAN->setSchema($self->getSchema());
  $TAN->setProbApprox($self->getProbApprox());
  $TAN->setTree($self->getTree());
  $self->setTAN($TAN);
}

1;
