package Durin::ProbClassification::ProbApprox::PAAdaptativeLaplace;

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
    
    my @ctArray = @$ct;

    $self->{COUNTTABLE} = $ct;
    $self->{COUNT} = ${$ctArray[0]};
# print "Count =",$self->{COUNT},"\n";
$self->{COUNTCLASS} = $ctArray[1];
$self->{COUNTXCLASS} = $ctArray[2];
$self->{COUNTXYCLASS} = $ctArray[3];
my @classValues = keys %{$ctArray[1]};
$self->{CLASSCARD} = $#classValues + 1;
# print "Class card =",$self->{CLASSCARD},"\n";
my $oneclass = $classValues[0];
$self->{ATTRIBUTECARD} = [];
foreach my $hash (@{$ctArray[2]->{$oneclass}})
  {
    my @l = keys %$hash;
    push @{$self->{ATTRIBUTECARD}},($#l + 1);
  }
my $i = 0;
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
    
    my $count = (1/100) *$self->{COUNT};
    my $LaplaceAddition = $self->{CLASSCARD};
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($self->{COUNTCLASS}{$classVal} + (1/$count)) / ($self->{COUNT} + $LaplaceAddition/$count);
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
  
    my $count = (1/100) *$self->{COUNT};  
    my $LaplaceAddition = $self->{ATTRIBUTECARD}[$attX] * $self->{ATTRIBUTECARD}[$attY] * $self->{CLASSCARD};
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($CXYClass + 1 / $count) / ($self->{COUNT} + $LaplaceAddition / $count);
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
    
 my $count = (1/100) *$self->{COUNT};
    
    my $LaplaceAddition = $self->{ATTRIBUTECARD}[$attX];
    if ($LaplaceAddition == 0)
    {
	print "Error horroroso\n";
      }
    return ($self->{COUNTXCLASS}{$classVal}[$attX]{$attXVal} + 1 / $count) / ($self->{COUNTCLASS}{$classVal} + $LaplaceAddition / $count);  
  }

sub getPYCondXClass
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
 my $count = (1/100) *$self->{COUNT};
  
    my $LaplaceAddition = $self->{ATTRIBUTECARD}[$attY];
    if ($LaplaceAddition == 0)
      {
	print "Error horroroso\n";
      }
    return ($CXYClass + 1/$count)/ ($self->{COUNTXCLASS}{$classVal}[$attX]{$attXVal} + $LaplaceAddition/$count);  
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
   my $count = (1/100) *$self->{COUNT};
    
    my $cardX = $self->{ATTRIBUTECARD}[$attX];
    my $cardY = $self->{ATTRIBUTECARD}[$attY];
    #my $cardClass = $self->{CLASSCARD};

    my $Numerator = ($CXYClass + 1/$count) * ($self->{COUNTCLASS}{$classVal} + $cardX * $cardY /$count);
    my $Denominator =  ($self->{COUNTXCLASS}{$classVal}[$attX]{$attXVal} + $cardY /$count) * ($self->{COUNTXCLASS}{$classVal}[$attY]{$attYVal} + $cardX/$count); 
    return $Numerator/$Denominator;  
  }
