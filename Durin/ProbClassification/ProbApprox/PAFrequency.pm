package Durin::ProbClassification::ProbApprox::PAFrequency;

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
    
    die "Durin::ProbClassification::ProbApprox::PALaplace clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub setCountTable
  {
    my ($self,$ct) = @_;
    
    #my @ctArray = @$ct;
    
    $self->{COUNTTABLE} = $ct;
    #$self->{COUNTTABLE}->getCounter(); = ${$ctArray[0]};
    #$self->{COUNTCLASS} = $ctArray[1];
    #$self->{COUNTXCLASS} = $ctArray[2];
    #$self->{COUNTXYCLASS} = $ctArray[3];
    #my @classValues = keys %{$ctArray[1]};
    #$self->{CLASSCARD} = $#classValues + 1;
    #my $oneclass = $classValues[0];
    #$self->{ATTRIBUTECARD} = [];
    #foreach my $hash (@{$ctArray[2]->{$oneclass}})
    #  {
#	my @l = keys %$hash;
#	push @{$self->{ATTRIBUTECARD}},($#l + 1);
#      }
    
  }

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;
    
    return $self->{COUNTTABLE}->getCountClass($classVal) / $self->{COUNTTABLE}->getCount();
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
    
    return $CXYClass / $self->{COUNTTABLE}->getCount();
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    
    return $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) / $self->{COUNTTABLE}->getCountClass($classVal);  
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
    return $CXYClass / $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal);  
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
    
    my $Denominator =  $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) * $self->{COUNTTABLE}->getCountXClass($classVal,$attY,$attYVal);
    my $Numerator = $CXYClass * $self->{COUNTTABLE}->getCountClass($classVal);

    #print "$classVal, CClass = ".$self->{COUNTTABLE}->getCountClass($classVal)."CXYClass = $CXYClass\n";
    #print "$Numerator / $Denominator\n";
    return $Numerator/$Denominator;  
  }
