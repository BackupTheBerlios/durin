package Durin::Classification::IO::CTSIOStandard;

use Durin::Data::IO::TSIOStandard;

@ISA = (Durin::Data::IO::TSIOStandard);
$IO_CLASS = "Durin::Classification::ClassedTableSchema";
$IO_FORMAT = "Standard";

use strict;

use Durin::Classification::ClassedTableSchema; 

sub write
{
    my ($self,$disp,$classed_table_sch) = @_;
    
    $disp->print("Class ".$classed_table_sch->getClassPos()."\n");
    $self->SUPER::write($disp,$classed_table_sch);
}
	       

sub read
{
    my ($class,$disp) = @_;
    my ($table,$line,$class_att,$sch);
     
    $line = $disp->getline();
    $line =~  /^Class (.*)\n$/;
    $class_att = $1;
    
    $sch = Durin::Classification::ClassedTableSchema->new();
    
    $class->SUPER::read_sch($disp,$sch);
    
    $sch->setClassByPos($class_att);
    return $sch;
}

1;
