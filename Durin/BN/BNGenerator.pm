package Durin::BN::BNGenerator;

use base Durin::ModelGeneration::ModelGenerator;

use Class::MethodMaker get_set => [-java => qw/ Schema IndepSet BN/];

use strict;
use warnings;

use Durin::Classification::ClassedTableSchema;
use Durin::DataStructures::Graph;
use Durin::BN::BN;

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
  
  $self->SUPER::init($input);
  
  
  ## Get the percentage of independent tables 
  
  #if (defined $input->{INDEPENDENCE_PERCENTAGE}) {
  #  $self->{INDEPENDENCE_PERCENTAGE} = $input->{INDEPENDENCE_PERCENTAGE};
  #}
}


sub generateModel {
  my ($self) = @_;
  
  my $fileName = $self->generateRandomBN($self->{Options});
  my $BN = $self->loadBNFromFile($fileName);

  return $BN;
}

sub generateRandomBN {
  my ($self,$options) = @_;
  
  #  nNodes
  #    the number of nodes in the networks that are generated. Default is 4. Note: nNodes must be larger than 3 (you can easily generate all directed acyclic graphs with 3 nodes). 
  #maxDegree
  #    The maximum degree of any node in the networks that are generated (the degree of a node is the sum of incoming and outgoing arcs). Default is (nNodes - 1). Note: maxDegree must be larger than 2 (you can easily enumerate all graphs with nNodes and maxDegree equal to 2). 
  #maxArcs
  #    The maximum number of arcs that can be present in the generated networks. Note that, for a given number of nodes and a given maximum degree, the number of arcs must satisfy some constraints. If the specified number of arcs is impossible, a message is printed. The default behavior is to ignore any constraint on the number of arcs. 
  #maxIW
  #    The maximum value of induced width in the generated networks. Induced width conveys the algorithmic complexity of inferences and, indirectly, it captures how dense the network is. The default behavior is to ignore any constraint on induced width.
  #nBNs
  #    The number of random Bayesian networks that are generated and actually saved in files. Default is 1. 
  #nTransitions
  #    The number of iterations (transitions in the Markov chain built by BNGenerator) between networks are generated and saved. Note that every iteration generates a new Bayesian network; after nTransitions , a network is saved in a file (and this process is repeated nBNs times). Default is (4 * nNodes * nNodes ). 
  #format
#    The output format for the generated networks. it can be either xml (in which case the output is in the XMLBIF format) or java (in which case the output is a Java program that can be used to input data into the EBayes library or xmljava (in which case both outputs are generated). Default is xml. 
  #nVal
  #    The maximum number of values for each variable (node) in the generated networks. Each variable has a random number of values between 2 and nVal. Default is 2 (every variable is binary). 
  #fName
  #    The name of the file(s) that will receive output networks. An extension will be appended to fName , depending on the value of format . If nBNs is larger than one, a sequence of files is generated. The file names are of the form fName X.format , where X is a number. Default is Graph . 
  #structure
  #    The type of network generated: either singly (in which case singly-connected networks will be generated) or multi (in which case multi-connected networks will be generated with Algorithm 1 of paper , if there is no constraint on induced width; otherwise, networks will be generated with Algorithm PMMixed of paper ). Singly connected networks are usually called polytrees. Note that multi option leads to the generation of generic graphs, including graphs that are singly connected, trees, and chains. But the probability of hitting a singly connected graph using the multi option is really small for large values of nNodes. Default is multi.
  
  if (!exists $options->{format}) {
    $options->{format} = "xml";
  }
  if (!exists $options->{fName}) {
    my $fileName = tmpnam();
    $options->{fName} = $fileName;
  }
  
  my $cmd = 'java BNGenerator';
  foreach my $option (keys %$options) {
    $cmd = $cmd." -".$option." ";
    if (defined $options->{$option}) {
      $cmd = $cmd.$options->{$option};
    }
  }
  print "$cmd\n";
  print `$cmd`;
  return $options->{fName}."1.xml";
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
  
  #print "VariableElement: ".$variableElement->toString()."\n";
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
  
  #print "DefinitionElement: ".$definitionElement->toString()."\n";
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
    #print "Parent pos: $parentPos\n";
    push @$parentPositions,$parentPos;
    #push @$parentValues,$schema->getAttributeByPos($parentPos)->getType()->getValues();
    $BN->addEdge($parentPos,$nodePos);
  }
  
  my $tableString = $definitionElement->getElementsByTagName("TABLE")->item(0)->getFirstChild()->getData();
  my @tableValues = split(/ /,$tableString);
  my $pos = 0;
  
  #  print "ParentPositions: ".join(",",@$parentPositions)."\n";

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

sub initSchemaGenerator {
  my ($self,$characteristics) = @_;

}

1;
