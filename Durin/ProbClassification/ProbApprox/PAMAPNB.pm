package Durin::ProbClassification::ProbApprox::PAMAPNB;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

sub new_delta
  {
  my ($class,$self) = @_;
  
  $self->{COUNTTABLE} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::ProbApprox::PABIBL clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub setCountTable
  {
    my ($self,$ct) = @_;
    
    #my @ctArray = @$ct;

    $self->{COUNTTABLE} = $ct;
    $self->{DATASETSIZE} = 1;
    #print "Selection of lambda for probability estimation: ",$self->{DATASETSIZE},"\n"; 
  }

# Fixes the lambda for probability approximation
#sub setLambda
#  {
#     my ($self,$lambda) = @_;
#    
#     $self->{DATASETSIZE} = $lambda;
#  }

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;
    my ($prob);
    if ($self->{COUNTTABLE}->getCountClass($classVal) > 0)
      {
        $prob = ($self->{COUNTTABLE}->getCountClass($classVal)) / ($self->{COUNTTABLE}->getCount());
      }
    else
      {
	$prob = 0.0000001/ ($self->{COUNTTABLE}->getCount());
      }
    #print "Prob{$classVal} = $prob\n";
    return $prob;
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    
    my $size = $self->{DATASETSIZE};

    my $denom1 = $self->{COUNTTABLE}->getNumAttValues($attX);
    
    if ($self->{COUNTTABLE}->getCountClass($classVal) > 0)
      {
	if ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) > 0) 
	  { 
	    return ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) / ($self->{COUNTTABLE}->getCountClass($classVal)));  
	  }
	else
	  {
	    return 0.0000001/($self->{COUNTTABLE}->getCountClass($classVal));
	  }
      } 
    else 
      {
	# It doesn't matter, the prediction will be 0 anyhow
	return 1;
      }
  }


