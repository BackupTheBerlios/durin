#Learning curve constructed by: 
#
# Sampling + CV
#

package Durin::Classification::Experimentation::CVLearningCurve;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

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
  
  my $input = $self->getInput();
  my $table = $input->{TABLE};
  my @proportionList = @{$input->{PROPORTIONLIST}};
  print "Proportion list = ".join(',',@proportionList)."\n";
  my @learningCurve = ();
  
  foreach my $trainProportion (@proportionList)
    {     
      my $splitter = new Durin::PP::Sampling::Sampler->new();
      {
	my $input = {};
	$input->{TABLE} = $table;
	$input->{PERCENTAGE} = $trainProportion;
	#$input->{FUNCTION} = sub
	#      {
	#	my ($row) = @_;
	#	
	#	print "Hola @$row\n";
	#      };
	
	$splitter->setInput($input);
      }
      print "Sampling proportion: $trainProportion\n";
      $splitter->run();
      print "Done\n";
      my $output = $splitter->getOutput();
      my $train = $output->{TRAIN};
      my $test = $output->{TEST};
      
      my $CV = Durin::Classification::Experimentation::CrossValidation->new();
      {
	my $input = $input->{CV};
	$input->{TABLE} = $train;
	$CV->setInput($input);
      }
      print "Cross validating over the sample";
      $CV->run();
      print "Done\n";
      my $CVResult = $CV->getOutput();
      push @learningCurve,([$trainProportion,$CVResult]);
    } 
  $self->setOutput(\@learningCurve);
}

1;
