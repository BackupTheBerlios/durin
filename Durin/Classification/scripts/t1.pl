use Durin::Classification::System;

#use Durin::NB::NBInducer;


#my $i = new Durin::NB::NBInducer;
my $Ind = Durin::Classification::Registry->getInducer("NB");

print $Ind."\n";
