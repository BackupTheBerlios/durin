# Contains the results of an application of a classification model to a dataset

package Durin::Classification::Experimentation::ModelApplication;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

sub new_delta 
{     
    my ($class,$self) = @_;
    
    $self->{OKS} = 0;
    $self->{WRONGS} = 0;
}

sub clone_delta
{  
  # my ($class,$self,$source) = @_;
  
  die "Durin::ProbClassification::ProbModelApplication::clone not implemented\n";
}

sub increaseOKs
  {
    my ($self) = @_; 

    $self->{OKS}++;
  }

sub setNumOKs
  {
    my ($self,$OKs) = @_;
    
    $self->{OKS} = $OKs;
  }

sub getNumOKs
  {
    my ($self) = @_; 

    return $self->{OKS};
  }

sub increaseWrongs
  {
    my ($self) = @_; 
    
    $self->{WRONGS}++;
  }

sub setNumWrongs
  {
    my ($self,$Wrongs) = @_;
    
    $self->{WRONGS} = $Wrongs;
  }

sub getNumWrongs
  {
    my ($self) = @_; 

    return $self->{WRONGS};
  }

sub getAccuracy
  {
    my ($self) = @_; 
    
    return ($self->{OKS} + 1) / ($self->{WRONGS} + $self->{OKS} + 2);
    #return ($self->{OKS} ) / ($self->{WRONGS} + $self->{OKS});
  }

sub getErrorRate
  {
    my ($self) = @_; 
    
    return ($self->{WRONGS} + 1) / ($self->{WRONGS} + $self->{OKS} + 2);

    #return ($self->{WRONGS} ) / ($self->{WRONGS} + $self->{OKS} );
  }

