# Contains the table of results that summarizes an experiment. That means it has:
# 
#  Method x Percentage x RunNumber
#

package Durin::Classification::Experimentation::ResultTable;

use Durin::Components::Data;

@ISA = (Durin::Components::Data);

use strict;

sub new_delta 
  {     
    my ($class,$self) = @_;
    
    $self->{RESULTLIST} = [];
    $self->{RESULTSCLASSIFIEDS} = {};
    $self->{PROPORTIONS} = {};
    $self->{MODELS} = {};
  }

sub clone_delta
  {  
    # my ($class,$self,$source) = @_;
    
    die "Durin::Classification::Experimentation::ResultTable::clone not implemented\n";
  }


sub addResult
  {
    my ($self,$runId,$trainProportion,$modelName,$modelApplication) = @_;
    
    if (!(exists $self->{PROPORTIONS}->{$trainProportion}))
      {
	$self->{PROPORTIONS}->{$trainProportion} = undef;
      }
    if (!(exists $self->{MODELS}->{$modelName}))
      {
	$self->{MODELS}->{$modelName} = undef;
      }
    
    # print $model->getName(),"\n";
    push @{$self->{RESULTLIST}},([$runId,$trainProportion,$modelName,$modelApplication]);
    $self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}->{$modelName} = $modelApplication;
  }

sub getResults
  {
    my ($self) = @_;
    
    return $self->{RESULTLIST};
  }

sub getResultsByModel
  {
    my ($self) = @_;
    
    my @resultList = ();   
    foreach my $runId (keys %{$self->{RESULTSCLASSIFIEDS}})
      {
	foreach my $trainProportion (keys %{$self->{RESULTSCLASSIFIEDS}->{$runId}})
	  {
	    my @runList = ();
	    foreach my $model (sort (keys %{$self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}}))
	      {
		push @runList,([$model,$self->{RESULTSCLASSIFIEDS}->{$runId}->{$trainProportion}->{$model}]);
	      }
	    push @resultList,([$runId,$trainProportion,\@runList]);
	  }
      }
    return \@resultList;
  }

sub getProportions
  {
    my ($self) = @_;
    
    my @list = (sort (keys %{$self->{PROPORTIONS}}));
    return \@list;
  }

sub getModels
  {
    my ($self) = @_;
    
    my @list = (sort (keys %{$self->{MODELS}}));
    return \@list;
  }

