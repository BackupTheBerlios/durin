package Durin::Data::IO::TSIOStandard;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "Durin::Data::TableSchema";
$IO_FORMAT = "Standard";

use strict;

use Durin::Data::TableSchema;
use Durin::Metadata::Attribute;
use Durin::Metadata::ATCreator;

sub write
{
    my ($class,$disp,$table_sch) = @_;
    my ($att,$attType,$att_list);
    
    
    $disp->print("NAME,TYPE,REST\n");    
    $att_list = $table_sch->getAttributeList();
    # print @$att_list , "\n";
    foreach $att (@$att_list)
    {
	$disp->print($att->getName(),",");
	$attType = $att->getType();
	$disp->print($attType->getName(),",");
	$disp->print($attType->getRest(),"\n");
    }
}

sub read
{
    my ($class,$disp) = @_;
    my ($table_sch);

    $table_sch = Durin::Data::TableSchema->new();
    
    read_sch($class,$disp,$table_sch);
    return $table_sch;
}

sub read_sch
{
  my ($class,$disp,$table_sch) = @_;
  my ($att,$attType);

  my $line = $disp->getline();
  
  if ($line ne "NAME,TYPE,REST\n")
    {
      die "Format error, first line: $line\n";
    }
  else
    {
      
      while ($line = $disp->getline())
	{
	  # We take the newline away
	  $line =~ /^(.*)\n$/;
	  $line = $1;
	  my ($name,$type,$rest) = split(/,/,$line);
	  $att = Durin::Metadata::Attribute->new(); 
	  $att->setName($name);
	  $attType = Durin::Metadata::ATCreator->create($type);
	  $attType->setRest($rest);
	  $att->setType($attType);
	  $table_sch->addAttribute($att);
	}
    }
}

1;
