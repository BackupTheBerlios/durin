package Durin::ProbClassification::ProbApprox::PABIBL;

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
    
    #my $size = $self->{DATASETSIZE} ;
    #my $size = $self->{COUNTTABLE}->getNumClasses();
    my $size = 1;
    
    my $denom = $self->{COUNTTABLE}->getNumClasses();
    my $prob =  ($self->{COUNTTABLE}->getCountClass($classVal) +  $size/$denom) / ($self->{COUNTTABLE}->getCount() + $size );

    #print "Count Class $classVal: ", $self->{COUNTTABLE}->getCountClass($classVal)," Total: ",$self->{COUNTTABLE}->getCount(),"\n";
    #print "Prob{$classVal}: $prob\n";
    
    return $prob;
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    
    #my $size = $self->{DATASETSIZE};
    #my $size = $self->{COUNTTABLE}->getNumAttValues($attX);
    my $size = 1;
    my $denom1 = $self->{COUNTTABLE}->getNumAttValues($attX);

    return ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) +  $size / $denom1) / ($self->{COUNTTABLE}->getCountClass($classVal) +  $size);  
  }

