package Durin::ModelGeneration::ModelGenerator;

#use Durin::Components::Process;
#use Durin::Basic::NamedObject;

#@ISA = qw(Durin::Components::Process Durin::Basic::NamedObject);
use base qw(Durin::Components::Process Durin::Basic::NamedObject);

# This is the base class for model generators.
# Model generators are processes that randomly
# generate models for the data. After the generation,
# these models will be used to generate the datasets 
# over which the learning will be performed.

# A model generator receives (at least):
#
# NUMBER_OF_MODELS -> Number of models
#
# and returns
#
# LIST_OF_MODELS -> list of models generated.

use Durin::TAN::RandomTANGenerator;
use Durin::BN::BNGenerator;
use Durin::Classification::ClassedTableSchema;
#use Durin::Metadata::Attribute;
use Durin::Metadata::ATCreator;

#{
#  package Durin::ModelGeneration::ModelGenerator::AttributeGenerator;
  
#  use base Durin::Basic::NamedObject

#  sub create {
#    my ($class,$characteristics) = @_;
    
    
#    #my $name = $characteristics->{METHOD_NAME};
#    #if ("Fixed" eq $name) {
    
      
#  }
  
  
#}



use strict;
use warnings;

sub new_delta {
  my ($class,$self) = @_;
  
  $self->{NUMBER_OF_MODELS} = 1; # By default generate 1 model.
  $self->{NUMBER_OF_ATTRIBUTES_GENERATOR}= sub {return 7;};
  $self->{NUMBER_OF_VALUES_GENERATOR}= sub {return POSIX::ceil(rand 1)+1};
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

sub create {
  my ($class,$characteristics) = @_;

  my $name = $characteristics->{METHOD_NAME};
  my $generator;
  
  if ("Multinomial" eq $name) {
    print "Generating samples from a huge multinomial\n";
    $generator = Durin::Multinomial::MultinomialModelGenerator->new();
  } elsif ("RandomTAN" eq $name) {
    print "Generating samples from a TAN\n";
    $generator = Durin::TAN::RandomTANGenerator->new();
  } elsif ("RandomBN" eq $name) {
    print "Generating samples from a BN\n";
    $generator = Durin::BN::BNGenerator->new();
  }
  $generator->initSchemaGenerator($characteristics);
  $generator->setInput($characteristics);
  return $generator;
}

sub initSchemaGenerator {
  my ($self,$characteristics) = @_;
  
  my ($numAttsGen, $numValsGen);
  {
    my $attGenCharacteristics = $characteristics->{ATTRIBUTE_GENERATOR};
    my $valGenCharacteristics = $characteristics->{VALUE_GENERATOR};
    $numAttsGen = sub {
      if ("Fixed" eq $attGenCharacteristics->{METHOD_NAME}) {
	return $attGenCharacteristics->{NUM_ATTRIBUTES};
      } elsif ("Random" eq $attGenCharacteristics->{METHOD_NAME}) {
	return int(rand($attGenCharacteristics->{NUM_ATTRIBUTES}-1))+2;
      }
    };
    $numValsGen = sub {
      if ("Fixed" eq $valGenCharacteristics->{METHOD_NAME}) {
	return $valGenCharacteristics->{NUM_VALUES};
      } elsif ("Random" eq $valGenCharacteristics->{METHOD_NAME}) {
	return int(rand($valGenCharacteristics->{NUM_VALUES}-1))+2;
      }
    };
  }
  for (my $i = 0 ; $i < 10 ; $i++) {
    print "Atts: ".&$numAttsGen()."\n";
    print "Vals: ".&$numValsGen()."\n";
  }
  $characteristics->{NUMBER_OF_ATTRIBUTES_GENERATOR} = $numAttsGen;
  $characteristics->{NUMBER_OF_VALUES_GENERATOR} = $numValsGen;
}

sub init($$) {
  my ($self,$input) = @_;

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
  
}


sub run($)
	{
	  my ($self) = @_;
	  
	  my $input = $self->getInput();
  
	  $self->init($input);
	  
  my $modelList = [];
  my $model;
  foreach my $i (1..$self->{NUMBER_OF_MODELS}) {
    $self->generateSchema();
    $model = $self->generateModel();
    push @$modelList,$model;
  }
  
  $self->setOutput($modelList);
}

# Returns a hash with model generator details
sub getDetails($) {
  my ($class) = @_;

  my $details = {}; 
  return $details;
}
	       
sub generateModel($) {
  my ($self) = @_;
  
  die "Durin::ModelGeneration::ModelGenerator::generateModel is pure virtual\n";
}
		  
		  # Generates the model schema (the attributes & its values)

sub generateSchema {
  my ($self) = @_;

  my $attGen = $self->{NUMBER_OF_ATTRIBUTES_GENERATOR};
  my $valGen = $self->{NUMBER_OF_VALUES_GENERATOR};
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
  $schema->setClassByPos(0);
  $self->setSchema($schema);
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
  
1;
