package Durin::Classification::System;

use Durin::Classification::Registry;
#use Durin::NB::MAPNBInducer;

sub BEGIN
{
    my @INDUCER_MODULES = qw(Durin::NB::MAPNBInducer Durin::NB::IndifferentNBInducer Durin::NB::BIBLInducer Durin::NB::NBInducer Durin::BMATAN::BMAFGGTANInducer Durin::BMATAN::BMACoherentCoherentTANInducer Durin::TAN::FGGTANInducer Durin::TAN::CoherentCoherentTANInducer Durin::TAN::CoherentMarginalsTANInducer Durin::TAN::FrequencyMarginalsTANInducer Durin::TAN::FrequencyHierarchicalMarginalsTANInducer Durin::TBMATAN::TBMATANInducer Durin::TBMATAN::SSTBMATANInducer Durin::TAN::CoherentLaplaceTANInducer Durin::TAN::CoherentFGGTANInducer Durin::TAN::FrequencyCoherentTANInducer Durin::TAN::FrequencyLaplaceTANInducer Durin::TAN::UTANInducer Durin::BMATAN::BMAUTANInducer Durin::BMATAN::BMACCMAPTANInducer Durin::TAN::CCMAPTANInducer Durin::RODE::BMARODEInducer);
    my ($module);
    print "Loading Inducer system\n";
    foreach $module (@INDUCER_MODULES)
    {
	print "\tLoading $module\n";
	eval "require $module";
	if ($@) {
	    print "Troubles loading $module:\n$@\n";
	}
	import $module;
	my $mdl = new $module;
	my $name = getName $mdl;
	print "\t\twhich contains inducer $name\n";
	Durin::Classification::Registry->register($name,$module);
    }
    print "Inducer system loaded\n";
}

1;
