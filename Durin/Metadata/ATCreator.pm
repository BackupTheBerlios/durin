package Durin::Metadata::ATCreator;

use strict;

use Durin::Metadata::AttributeType;
use Durin::Metadata::ATCategorical;
use Durin::Metadata::ATString;
use Durin::Metadata::ATNumber;
use Durin::Metadata::ATUnknown;
use Durin::Metadata::ATDate;

sub create
{
    my ($self,$type) = @_;
    my $attType;

    if ($type eq "Categorical")
    {
	$attType = Durin::Metadata::ATCategorical->new();
    }
    else
    {
	if ($type eq "String")
	{
	    $attType = Durin::Metadata::ATString->new();
	}
	else
	{
	    if ($type eq "Number")
	    {
		$attType = Durin::Metadata::ATNumber->new();
	    }
	    else
	    {
	      if ($type eq "Date")
		{
		  $attType = Durin::Metadata::ATDate->new();
		}
	      else
		{
		  $attType = Durin::Metadata::ATUnknown->new();
		}
	    }
	}
    }
    return $attType;
}

1;
