package Durin::ProbClassification::ProbApprox::PAFG;

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
    #$self->{COUNT} = ${$ctArray[0]};
    #$self->{COUNTCLASS} = $ctArray[1];
    #$self->{COUNTXCLASS} = $ctArray[2];
    #$self->{COUNTXYCLASS} = $ctArray[3];
    #my @classValues = keys %{$ctArray[1]};
    #$self->{CLASSCARD} = $#classValues + 1;
    #my $oneclass = $classValues[0];
    #$self->{ATTRIBUTECARD} = [];
    #foreach my $hash (@{$ctArray[2]->{$oneclass}})
    #  {
	#my @l = keys %$hash;
	#push @{$self->{ATTRIBUTECARD}},($#l + 1);
      #}
    #$self->{COUNTX} = ();
    
    #print "Hello. Starting summarization\n";
    my $att;
    for ($att = 0 ; $att <=  $self->{COUNTTABLE}->getNumAtts() ; $att++)
      {
	#print "A\n";
	my @attValues =  @{$self->{COUNTTABLE}->getAttValues($att)};
	#print "B\n";
	foreach my $value (@attValues)
	  {
	    $self->{COUNTX}[$att]{$value} = 0;
	  }
      }
    
    for ($att = 0 ; $att <=  $self->{COUNTTABLE}->getNumAtts() ; $att++)
      {
	#print "B, $att\n";
	#if ($att != $self->{COUNTTABLE}->getClassIndex())
	#  {
	    my @attValues = @{$self->{COUNTTABLE}->getAttValues($att)};
	    foreach my $value (@attValues)
	      {
		foreach my $classVal (@{$self->{COUNTTABLE}->getClassValues()})
		  {
		    #print "ClassVal: $classVal, $att, $value :".$self->{COUNTTABLE}->getCountXClass($classVal,$att,$value)."\n";
		    $self->{COUNTX}[$att]{$value} += $self->{COUNTTABLE}->getCountXClass($classVal,$att,$value);
		  }
	      }
	#  }
      }

#     for ($att = 0 ; $att <=  $self->{COUNTTABLE}->getNumAtts() ; $att++)
#      {
#
#	my @attValues =  @{$self->{COUNTTABLE}->getAttValues($att)};
#
#	foreach my $value (@attValues)
#	  {
#	    #print " $att, $value  -> ".$self->{COUNTX}[$att]{$value}."\n";;
#	  }
#      }
    print "Finished\n";
    
    $self->{NZERO} = 5;
  }

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;
    
    my $NZERO = $self->{NZERO};
    my $num = $self->{COUNTTABLE}->getCountClass($classVal) + $NZERO * $self->{COUNTTABLE}->getCountClass($classVal) / $self->{COUNTTABLE}->getCount();
    my $denom = $self->{COUNTTABLE}->getCount() + $NZERO;
    return $num/$denom;
  }

#sub getPXYClass
#  {
#    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
#
#    my $CXYClass;
#    if ($attX > $attY)
#      {
#	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attX]{$attXVal}[$attY]{$attYVal};
#	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
#      }
#    else
#      {
#	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attY]{$attYVal}[$attX]{$attXVal};
#	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
#      }
#    
#    return $CXYClass / $self->{COUNT};
#  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;

    my $NZERO = $self->{NZERO};
    my $num = $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $NZERO * $self->{COUNTX}[$attX]{$attXVal} / $self->{COUNTTABLE}->getCount();
    my $denom = $self->{COUNTTABLE}->getCountClass($classVal) + $NZERO;
    return  $num / $denom ;  
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
    
    my $NZERO = $self->{NZERO};
    my $num = $CXYClass + $NZERO * $self->{COUNTX}[$attY]{$attYVal} / $self->{COUNTTABLE}->getCount();
    #print $num."\n";
    my $denom = $self->{COUNTTABLE}->getCountXClass($classVal,$attX,$attXVal) + $NZERO;
    return $num / $denom;  
  }

#sub getSinergy
#  {
#    my ($self,$classVal,$attX,$attXVal,$attY,$attYVal) = @_;
#    
#    my $CXYClass;
#    
#    if ($attX > $attY)
#      {
#	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attX]{$attXVal}[$attY]{$attYVal};
#	# print " A CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
#      }
#    else
#      {
#	$CXYClass = $self->{COUNTXYCLASS}{$classVal}[$attY]{$attYVal}[$attX]{$attXVal};
#	# print " B CXYClass{$classVal}[$attX]{$attXVal}[$attY]{$attYVal} = $CXYClass\n";
#      }
#    
#    my $NZERO = $self->{NZERO};
#    
#    my $Numerator = ($CXYClass) * ($self->{COUNTCLASS}{$classVal});
#    my $Denominator =  ($self->{COUNTXCLASS}{$classVal}[$attX]{$attXVal}) * ($self->{COUNTXCLASS}{$classVal}[$attY]{$attYVal}); 
#    
#    return $Numerator/$Denominator;  
#  }
