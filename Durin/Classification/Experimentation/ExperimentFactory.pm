#
# This object is the base for ALL experiments from January 2004 on.

package Durin::Classification::Experimentation::ExperimentFactory;

use Durin::Classification::Experimentation::IrvineExperiment;
use Durin::Classification::Experimentation::ArtificialExperiment2;

use strict;
use warnings;

sub createExperiment  {
  my ($class,$properties) = @_;
  
  my $type = $properties->{Type};
  print "Experiment type: $type\n";
  my $exp;
  if ($type eq "IrvineExperiment") {
    #print "Init\n";
    # Here we should manage the different versions. By now it is only one
    $exp = new Durin::Classification::Experimentation::IrvineExperiment(%$properties); }
  elsif ($type eq "IrvineTask") {
    $exp = new Durin::Classification::Experimentation::IrvineTask(%$properties);
  } elsif ($type eq "ArtificialExperiment") {
    # Here we should manage the different versions. By now it is only one
    $exp = new Durin::Classification::Experimentation::ArtificialExperiment2(%$properties);
  } elsif ($type eq "ArtificialTask") {
    $exp = new Durin::Classification::Experimentation::ArtificialTask(%$properties);
  }
  return $exp;
}
 
1;
