package Durin::ProbClassification::ProbApprox::PAFG;

use Durin::Classification::Model;

@ISA = (Durin::Classification::Model);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{COUNTTABLE} = undef; 
    $self->{NZERO} = $self->getNZero();
  }

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    die "Durin::ProbClassification::ProbApprox::PAFG clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub getNZero {
  return 5;
}

sub setCountTable
  {
    my ($self,$ct) = @_;
    
    #my @ctArray = @$ct;
    
    $self->{COUNTTABLE} = $ct;
    
    #print "Hello. Starting summarization\n";
    my $att;
    for ($att = 0 ; $att <  $self->{COUNTTABLE}->getNumAtts() ; $att++)
      {
	#print "A\n";
	my @attValues =  @{$self->{COUNTTABLE}->getAttValues($att)};
	#print "B\n";
	foreach my $value (@attValues)
	  {
	    $self->{COUNTX}[$att]{$value} = 0;
	  }
      }
    
    for ($att = 0 ; $att <  $self->{COUNTTABLE}->getNumAtts() ; $att++)
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
  }

sub getCountTable
  {
    my ($self) = @_;
    
    return $self->{COUNTTABLE};
  }

sub getPClass
  {
    my ($self,$classVal) = @_;
    
    #my $NZERO = $self->{NZERO};
    my $num = $self->{COUNTTABLE}->getCountClass($classVal);
    # + $NZERO * $self->{COUNTTABLE}->getCountClass($classVal) / $self->{COUNTTABLE}->getCount();
    my $denom = $self->{COUNTTABLE}->getCount();
      # + $NZERO;

    return $num/$denom;
  }

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

sub getDetails()
  {
    my ($class) = @_;
    
    return {"PAFG softening constant"=> $class->getNZero()};
  }
