package Durin::Classification::IO::CTSIOMineset;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "Durin::Classification::ClassedTableSchema";
$IO_FORMAT = "Mineset";

use strict;

use Durin::Classification::ClassedTableSchema; 
use Durin::Utilities::StringUtilities;

sub write
  {
    my ($self,$disp,$classedTableSch) = @_;
    
    my $classNum = $classedTableSch->getClassPos();
    my $classAtt = $classedTableSch->getAttributeByPos($classNum);
    my @values = @{$classAtt->getType()->getValues()};
    
    # Write the values of the class. In Mineset the class appears always first int the .names file.
    
    replaceForbiddenValues(\@values);

    $disp->print("\n");
    $disp->print(join(",",@values)."\n");
    $disp->print("\n");
    
    # Write the rest of attributes.
    
    my $attList = $classedTableSch->getAttributeList();
    # print @$att_list , "\n";
    foreach my $att (@$attList)
      {
	if ($att != $classAtt)
	  {
	    $disp->print($att->getName(),": \t");
	    if (Durin::Metadata::ATNumber->isNumber($att))
	      {
		$disp->print("continuous\n");
	      }
	    else
	      {
		if (Durin::Metadata::ATCategorical->isCategorical($att))
		  {
		    @values = @{$att->getType()->getValues()}; 
		    replaceForbiddenValues(\@values);
		    $disp->print(join(", ",@values)."\n");
		  }
		else
		  {
		    die "Durin::Data::CTSIOMineset: Unknown attribute type\n";
		  }
	      }
	  }
      }
  }
	      


sub read
{
    my ($class,$disp) = @_;

    die "Durin::Data::CTSIOMineset: NYI\n";
    

#    my ($table,$line,$class_att,$sch);
#     
#    $line = $disp->getline();
#    $line =~  /^Class (.*)\n$/;
#    $class_att = $1;
#    
#    $sch = Durin::Classification::ClassedTableSchema->new();
#    
#    $class->SUPER::read_sch($disp,$sch);
#    
#    $sch->setClassByPos($class_att);
#    return $sch;
}
 
# This function replaces the dots and substitutes them with minuses.

sub replaceForbiddenValues
  {
    my ($valuesRef) = @_;
    
    my $i = 0;
    foreach my $value (@$valuesRef)
      {
	$valuesRef->[$i] =~ tr/\./\-1/;
	$valuesRef->[$i] =~ tr/\|/\-2/;
	$valuesRef->[$i] =~ tr/\?/\-3/;
	$i++;
      }
  }
