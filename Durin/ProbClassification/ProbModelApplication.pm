# Contains the results of an application of a classification model to a dataset

package Durin::ProbClassification::ProbModelApplication;

use Durin::Classification::Experimentation::ModelApplication;
use Durin::Utilities::MathUtilities;
@ISA = (Durin::Classification::Experimentation::ModelApplication);

use strict;

sub new_delta 
{     
    my ($class,$self) = @_;
    
    $self->{LOGP} = 0;
}

sub clone_delta
{  
  # my ($class,$self,$source) = @_;
  
  die "Durin::ProbClassification::ProbModelApplication::clone not implemented\n";
}

sub addPClass
  {
    my ($self,$PClass) = @_;
    
    if ($PClass <= 0)
      {
	print "A probability evaluated to 0 or even less. Just another illogical prediction\n";
	$self->{LOGP} += 15000; # Just something big
      }
    else
      {
	$self->{LOGP} -= Durin::Utilities::MathUtilities::log10($PClass);
      }
  }

sub setLogP
  {
    my ($self,$LogP) = @_;
    
    $self->{LOGP} = $LogP;
  }

sub getLogP
  { 
    my ($self) = @_;
    
    return $self->{LOGP};
  }

sub setAUC
  {
    my ($self,$AUC) = @_;
    
    $self->{AUC} = $AUC;
  }

sub getAUC
  { 
    my ($self) = @_;
    
    return $self->{AUC};
  }
