package Durin::ProbClassification::ProbApprox::PAIndifferentNB;

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
    
    die "Durin::ProbClassification::ProbApprox::PAIndifferentNB clone not implemented";
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub setCountTable
  {
    my ($self,$ct) = @_;
    
    #my @ctArray = @$ct;

    $self->{COUNTTABLE} = $ct;
    
    

    my $classAttNumber = $ct->getClassIndex();
    $self->{DATASETSIZE} = 0;
    my $i;
    for ($i = 0 ; $i < $ct->getNumAtts() ; $i++)
      {
	if ($i != $classAttNumber)
	  {
	    print "Attribute $i has ".$ct->getNumAttValues($i)." values\n";
	    $self->{DATASETSIZE} += $ct->getNumAttValues($i);
	  }
      }
    print "Size : ",$self->{DATASETSIZE},"\n";
    $self->{REFERENCECLASS} = $ct->getClassValues()->[0];
    
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
    #my $prob = 1;
    
    my $ct = $self->{COUNTTABLE};
    my $size = $self->{DATASETSIZE};	
    # We have to substract 1 due to the class.
    my $N = $ct->getNumAtts() - 1;
    my $nl = $ct->getCountClass($classVal);
    my $addition =  1 + $size - $N;
    my $num = $nl + $addition;
    my $K = $ct->getNumClasses();
    my $denom = $ct->getCount() + $K * $addition;
    my $prob = $num/$denom;
    
    
    #if (!($classVal eq $self->{REFERENCECLASS}))
    #  {
#	my $lp = $self->{REFERENCECLASS};
#	my $ct = $self->{COUNTTABLE};
#	my $N = $ct->getNumAtts();
#	my $nl = $ct->getCountClass($classVal);
#	my $nlp = $ct->getCountClass($lp);
#	my $size = $self->{DATASETSIZE};
#	
#	my $i = 1;
#	print "NL/NLP: $nl/$nlp\n";
#	while ($i <= ($N +1))
#	  {
#	    my $num = ($N + 1) * ($nl + $i) - $N + $size;
#	    my $denom = ($N + 1) * ($nlp + $i) - $N + $size;
#	    $prob = $prob * $num/$denom;
#	    #print "Quotient: $num/$denom\n";
#	   
#	    $i++;
#	  }
#      }
#     
    #print "Count Class $classVal: ", $nl," Total: ",$ct->getCount(),"\n";
    #print "Prob{$classVal}: $prob\n";
    
    
    return $prob;
  }

sub getPXCondClass
  {
    my ($self,$classVal,$attX,$attXVal) = @_;
     
    my $ct = $self->{COUNTTABLE};
    my $nl = $ct->getCountClass($classVal);
    
    my $num = ($ct->getCountXClass($classVal,$attX,$attXVal) + 1);
    my $denom = ($nl + $ct->getNumAttValues($attX));
    my $prob = $num/$denom;
     # }
    #my $prob = 1;
    
    #if (!($classVal eq $self->{REFERENCECLASS}))
     # {
#	my $size = $self->{DATASETSIZE};
	#my $lp = $self->{REFERENCECLASS};
	#my $ct = $self->{COUNTTABLE};
	#my $nl = $ct->getCountClass($classVal);
	#my $nlp = $ct->getCountClass($lp);
	
	#my $num = ($nlp + $ct->getNumAttValues($attX)) * ($ct->getCountXClass($classVal,$attX,$attXVal) + 1);
	#my $denom = ($nl + $ct->getNumAttValues($attX)) * ($ct->getCountXClass($lp,$attX,$attXVal) + 1);
	#$prob = $num/$denom;
     # }
    return $prob;
  }

