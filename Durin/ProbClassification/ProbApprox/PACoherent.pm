package Durin::ProbClassification::ProbApprox::PACoherent;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;
use warnings;

sub new_delta
  {
  my ($class,$self) = @_;
  
  $self->{COUNTTABLE} = undef; 
  $self->{DATASETSIZE} = $self->getLambda();
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::ProbApprox::PACoherent clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub getLambda {
  return 10;
}

sub setCountTable
  {
    my ($self,$ct) = @_;
    
    #my @ctArray = @$ct;

    $self->{COUNTTABLE} = $ct;
  }

# Fixes the lambda for probability approximation
#sub setLambda
#  {
#     my ($self,$lambda) = @_;
#    
#     $self->{DATASETSIZE} = $lambda;
# }

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;
    
    my $size = $self->{DATASETSIZE};
    
    my $denom = $self->{COUNTTABLE}->getNumClasses();
    return ($self->{COUNTTABLE}->getCountClass($classVal) +  $size / $denom) / ($self->{COUNTTABLE}->getCount() + $size );
  }

sub getPXYClass
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
    
    my $CXYClass;
    if ($attX > $attY)
      {
	$CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    else
      {
	$CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    
    my $size = $self->{DATASETSIZE};
    my $denom = $self->{COUNTTABLE}->getNumAttValues($attX) * $self->{COUNTTABLE}->getNumAttValues($attY) * $self->{COUNTTABLE}->getNumClasses();
    
    return ($CXYClass +  $size / $denom) / ($self->{COUNTTABLE}->getCount() + $size );
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    
    my $size = $self->{DATASETSIZE};
    my $denom1 = $self->{COUNTTABLE}->getNumClasses() * $self->{COUNTTABLE}->getNumAttValues($attX);
    my $denom2 = $self->{COUNTTABLE}->getNumClasses();
    return ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) +  $size / $denom1) / ($self->{COUNTTABLE}->getCountClass($classVal) +  $size / $denom2);  
  }

sub getPYCondXClass
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
    
    my $CXYClass;
    
    if ($attX > $attY)
      {
	$CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    else
      {
	$CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    
    my $size = $self->{DATASETSIZE};
    my $denom1 = $self->{COUNTTABLE}->getNumClasses() * $self->{COUNTTABLE}->getNumAttValues($attX) * $self->{COUNTTABLE}->getNumAttValues($attY);
    my $denom2 = $self->{COUNTTABLE}->getNumClasses() * $self->{COUNTTABLE}->getNumAttValues($attX);
    return ($CXYClass +  $size / $denom1)/ ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) +  $size / $denom2);  
  }

sub getSinergy
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
    
    my $CXYClass;
    
    if ($attX > $attY)
      {
	$CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attX,$attXVal,$attY,$attYVal);
	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    else
      {
	$CXYClass = $self->{COUNTTABLE}->getCountXYClass($classVal,$attY,$attYVal,$attX,$attXVal);
	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    
    #my $cardX = $self->{ATTRIBUTECARD}[$attX];
    #my $cardY = $self->{ATTRIBUTECARD}[$attY];
    #my $cardClass = $self->{COUNTTABLE}->getNumClasses();
    my $size = $self->{DATASETSIZE};
    my $denom1 = $self->{COUNTTABLE}->getNumClasses() * $self->{COUNTTABLE}->getNumAttValues($attX) * $self->{COUNTTABLE}->getNumAttValues($attY);
    my $denom2 = $self->{COUNTTABLE}->getNumClasses();
    my $denom3 = $self->{COUNTTABLE}->getNumClasses() * $self->{COUNTTABLE}->getNumAttValues($attX);
    my $denom4 = $self->{COUNTTABLE}->getNumClasses() * $self->{COUNTTABLE}->getNumAttValues($attY);
    my $Numerator = ($CXYClass +  $size / $denom1) * ($self->{COUNTTABLE}->getCountClass($classVal) +  $size / $denom2);
    my $Denominator =  ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $size / $denom3) * ($self->{COUNTTABLE}->getCountXClass($classVal,$attY,$attYVal) + $size / $denom4); 
    return $Numerator/$Denominator;  
  }

sub getDetails()
  {
    my ($class) = @_;
    
    return {"PACoherent softening constant"=> $class->getLambda()};
  }
