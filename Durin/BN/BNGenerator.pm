package Durin::BN::BNGenerator;

use base Durin::ModelGeneration::ModelGenerator;

use Class::MethodMaker get_set => [-java => qw/ Schema IndepSet BN/];

use strict;
use warnings;

use Durin::Classification::ClassedTableSchema;
use Durin::DataStructures::Graph;

use XML::DOM;
use POSIX;

sub new_delta {
  my ($class,$self) = @_;
  
  #$self->{INDEPENDENCE_PERCENTAGE} = 0;
  #$self->setMultinomialGenerator(Durin::Math::Prob::MultinomialGenerator->new());
  
}

sub clone_delta {
  my ($class,$self,$source) = @_;
  
  die "Durin::TAN::BNGenerator clone not implemented";
}

sub init($$) {
  my ($self,$input) = @_;
  
  #$self->SUPER::init($input);
  
  ## Get the percentage of independent tables 
  
  #if (defined $input->{INDEPENDENCE_PERCENTAGE}) {
  #  $self->{INDEPENDENCE_PERCENTAGE} = $input->{INDEPENDENCE_PERCENTAGE};
  #}
}

sub generateModel {
  my ($self) = @_;
  
  my $fileName = $self->generateRandomBN();
  my $BN = $self->loadBNFromFile($fileName);

  return $BN;
}

sub generateRandomBN {
  my ($self) = @_;
  
  my $fileName = tmpnam();
  print `java BNGenerator -format xml -fName $fileName`;
  return $fileName."1.xml";
}

sub loadBNFromFile {
  my ($class,$fileName) = @_;
  
  my $BN = Durin::BN::BN->new;
  my $parser = new XML::DOM::Parser;
  my $doc = $parser->parsefile ($fileName);
  
  # print all HREF attributes of all CODEBASE elements 
  my $bif=  $doc->getElementsByTagName("BIF")->item(0);
    
  my $network =  $bif->getElementsByTagName("NETWORK")->item(0);
  
  my $name = $network->getElementsByTagName("NAME")->item(0)->getFirstChild()->getData();
  $BN->setName($name);
  
  # Load schema (variables and its possible values)
  
  my $schema = Durin::Classification::ClassedTableSchema->new();
  my @variables = $network->getElementsByTagName("VARIABLE");
  foreach my $variableElement (@variables) {
    $class->addVariableElement($variableElement,$schema);
  }
  $schema->setClassByPos(0);
  $BN->setSchema($schema);
  
  # Load dependency graph and contingency tables
  
  #my $graph = Durin::DataStructures::Graph->new();
  #my $contingencyTableHash = {};
  my @definitions = $network->getElementsByTagName("DEFINITION");
  foreach my $definitionElement (@definitions) {
    $class->addDefinitionElement($definitionElement,$BN);
  }
  
  $doc->dispose;
  return $BN;	
}

sub addVariableElement {
  my ($self,$variableElement,$schema) = @_;
  
  my $name = $variableElement->getElementsByTagName("NAME")->item(0)->getFirstChild()->getData();
  
  print "VariableElement: ".$variableElement->toString()."\n";
  my $att = Durin::Metadata::Attribute->new();
  $att->setName($name);
  my $attType = Durin::Metadata::ATCreator->create("Categorical");
  my $attValList = [];
  my @outcomes = $variableElement->getElementsByTagName("OUTCOME");
  foreach my $outcome (@outcomes) {
    #print "Val: ".$outcome->getFirstChild()->getData()."\n";
    #->getFirstChild()->getData();
    push @$attValList,$outcome->getFirstChild()->getData();
  }
  $attType->setRest(join(':',@$attValList));
  $att->setType($attType);
  $schema->addAttribute($att);
}

sub addDefinitionElement {
  my ($self,$definitionElement,$BN) = @_;
  
  print "DefinitionElement: ".$definitionElement->toString()."\n";
  my $schema = $BN->getSchema();
  my $nodeName = $definitionElement->getElementsByTagName("FOR")->item(0)->getFirstChild()->getData();
  my $nodePos = $schema->getPositionByName($nodeName);
  my $nodeValues = $schema->getAttributeByPos($nodePos)->getType()->getValues();
  
  my @parents = $definitionElement->getElementsByTagName("GIVEN");
  my $parentPositions =[];
  my $parentsValues = [];
  foreach my $parent (@parents) {
    my $parentName = $parent->getFirstChild()->getData();
    my $parentPos = $schema->getPositionByName($parentName);
    push @$parentPositions,$parentPos;
    #push @$parentValues,$schema->getAttributeByPos($parentPos)->getType()->getValues();
    $BN->addEdge($parentPos,$nodePos);
  }
  
  my $tableString = $definitionElement->getElementsByTagName("TABLE")->item(0)->getFirstChild()->getData();
  my @tableValues = split(/ /,$tableString);
  my $pos = 0;
  
  print "ParentPositions: ".join(",",@$parentPositions)."\n";

  if ((scalar @$parentPositions) > 0){
    my $parentConfigurations = $schema->generateAllConfigurations($parentPositions);
    foreach my $parentConfiguration (@$parentConfigurations) {
      my $conditionalProbabilityTable = ();
      foreach my $nodeVal (@$nodeValues) {
	my $prob = shift @tableValues;
	push @$conditionalProbabilityTable,$prob;
      }
      $BN->addCPT($nodePos,$parentConfiguration,$conditionalProbabilityTable);
    }
  } else {
    $BN->addCPT($nodePos,[],\@tableValues);
  }
}

1;
