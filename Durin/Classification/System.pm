package Durin::Classification::System;

use Durin::Classification::Registry;

sub BEGIN
{
  my @INDUCER_MODULES = qw(Durin::NB::MAPNBInducer Durin::NB::IndifferentNBInducer Durin::NB::BIBLInducer Durin::NB::NBInducer Durin::BMATAN::BMAFGGTANInducer Durin::BMATAN::BMACoherentCoherentTANInducer Durin::TAN::FGGTANInducer Durin::TAN::CoherentCoherentTANInducer );
  my ($module);
  print "Loading Inducer system\n";
  foreach $module (@INDUCER_MODULES)
    {
      print "\tLoading $module\n";
      eval "require $module";
      import $module;
      my $mdl = new $module;
      my $name = getName $mdl;
      print "\t\twhich contains inducer $name\n";
      Durin::Classification::Registry->register($name,$module);
    }
  print "Inducer system loaded\n";
}

1;
