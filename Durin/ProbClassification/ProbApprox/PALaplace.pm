package Durin::ProbClassification::ProbApprox::PALaplace;

use Durin::Classification::Model;;

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
    
    $self->{COUNTTABLE} = $ct;
    
    #my @ctArray = @$ct;

#    $self->{COUNTTABLE} = $ct;
#    $self->{COUNT} = ${$ctArray[0]};
## print "Count =",$self->{COUNT},"\n";
#$self->{COUNTCLASS} = $ctArray[1];
#$self->{COUNTXCLASS} = $ctArray[2];
#$self->{COUNTXYCLASS} = $ctArray[3];
#my @classValues = keys %{$ctArray[1]};
#$self->{CLASSCARD} = $#classValues + 1;
## print "Class card =",$self->{CLASSCARD},"\n";
#my $oneclass = $classValues[0];
#$self->{ATTRIBUTECARD} = [];
#foreach my $hash (@{$ctArray[2]->{$oneclass}})
#  {
#    my @l = keys %$hash;
#    push @{$self->{ATTRIBUTECARD}},($#l + 1);
#  }
#my $i = 0;
#foreach my $card (@{$self->{ATTRIBUTECARD}})
#  {
    # print "Cardinality $i = ",$card,"\n";
#    $i++;
#  }

}

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;
 
    my $LaplaceAddition = $self->{COUNTTABLE}->getNumClasses();
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($self->{COUNTTABLE}->getCountClass($classVal) + 1) / ($self->{COUNTTABLE}->getCount() + $LaplaceAddition);
  }

sub getPXYClass
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;

    my $CXYClass;
    if ($attX > $attY)
      {
	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attX]{$attXVal}[$attY]{$attYVal};
	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    else
      {
	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attY]{$attYVal}[$attX]{$attXVal};
	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    
    my $LaplaceAddition = $self->{ATTRIBUTECARD}[$attX] * $self->{ATTRIBUTECARD}[$attY] * $self->{CLASSCARD};
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($CXYClass + 1) / ($self->{COUNT} + $LaplaceAddition);
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    

    my $LaplaceAddition = $self->{COUNTTABLE}->getNumAttValues($attX);
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + 1) / ($self->{COUNTTABLE}->getCountClass($classVal) + $LaplaceAddition);  
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
    my $LaplaceAddition = $self->{COUNTTABLE}->getNumAttValues($attY);
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($CXYClass + 1)/ ($self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $LaplaceAddition);  
  }

sub getSinergy
  {
    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
    
    my $CXYClass;
    
    if ($attX > $attY)
      {
	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attX]{$attXVal}[$attY]{$attYVal};
	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    else
      {
	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attY]{$attYVal}[$attX]{$attXVal};
	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
      }
    
    my $cardX = $self->{ATTRIBUTECARD}[$attX];
    my $cardY = $self->{ATTRIBUTECARD}[$attY];
    #my $cardClass = $self->{CLASSCARD};

    my $Numerator = ($CXYClass + 1) * ($self->{COUNTCLASS}{$classVal} + $cardX * $cardY);
    my $Denominator =  ($self->{COUNTXCLASS}{$classVal}[$attX]{$attXVal} + $cardY) * ($self->{COUNTXCLASS}{$classVal}[$attY]{$attYVal} + $cardX); 
   
    return $Numerator/$Denominator;  
  }
