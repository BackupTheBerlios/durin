package Durin::DataStructures::TDIOYYMMDD;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "DataStructures::TimeDate";
$IO_FORMAT = "YYMMDD";

use strict;

use Durin::DataStructures::TimeDate; 

sub write
{
  die "NYI\n";
    #my ($self,$disp,$time) = @_;
    
    #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    #  localtime($time);
    
    #my $YY = $year % 100; 
    #$disp->print("%d$YY
    #$disp->print("Class ".$classed_table_sch->getClassPos()."\n");
    #$self->SUPER::write($disp,$classed_table_sch);
}
	       

sub read
{
    my ($class,$disp) = @_;
    my ($line);
     
    $line = $disp->get();
    my $year = 
    
    $sch = Durin::Classification::ClassedTableSchema->new();
    
    $class->SUPER::read_sch($disp,$sch);
    
    $sch->setClassByPos($class_att);
    return $sch;
}

1;
