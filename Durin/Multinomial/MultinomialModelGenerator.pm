package Durin::Multinomial::MultinomialModelGenerator;

use strict;
use warnings;

use Class::MethodMaker get_set => [-java => qw/ Schema MultinomialGenerator/];

use Durin::ModelGeneration::ModelGenerator;

@Durin::Multinomial::MultinomialModelGenerator::ISA = qw(Durin::ModelGeneration::ModelGenerator);

use Durin::Math::Prob::MultinomialGenerator;
use Durin::Multinomial::MultinomialModel;

sub new_delta {
  my ($class,$self) = @_;

  $self->setMultinomialGenerator(Durin::Math::Prob::MultinomialGenerator->new());
}

sub clone_delta { 
  my ($class,$self,$source) = @_;
}

#sub init($$) {
#  my ($self,$input) = @_;
#
#  $self->SUPER::init($input);
#}

sub generateModel($) {
  my ($self) = @_;
 
  my $schema = $self->getSchema();
  my $cardinalities = [];
  foreach my $att (@{$schema->getAttributeList()}) {
    push @$cardinalities,$att->getType()->getCardinality();
  }
  my $model = Durin::Multinomial::MultinomialModel->new();
  my $distribution = $self->getMultinomialGenerator()->generateMultidimensionalMultinomial($cardinalities);
  $model->setDistribution($distribution);
  $model->setSchema($schema);

  return $model;
}


# Returns a hash with model generator details
sub getDetails($) {
  my ($class) = @_;

  my $details = {}; 
  return $details;
}
	       
1;
