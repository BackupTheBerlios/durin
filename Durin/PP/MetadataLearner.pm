# This file provides basic facility for metadata generation from ColumnedData

package Durin::PP::MetadataLearner;

use strict;

use Durin::Metadata::Table;
use Durin::Data::TableSchema;
use Durin::Metadata::Attribute;
use Durin::Metadata::AttributeType;
use Durin::Metadata::ATCategorical;
use Durin::Metadata::ATCreator;
use Durin::Utilities::StringUtilities;

sub InduceStructure
{
  my ($self,$inFile,$max,$class) = (@_);
  my ($nfields,$i,@type,@difs,$row,@values);
  my ($colInfo);
  
  #my  = $inFile->getline();
  #$line = Durin::Utilities::StringUtilities::removeCtrlMEnter($line);
  #my @array = split(/,/,$line);
  #$row = $inFile->getNextRow();
  
  #$nfields = $#array+1;
  my $headers = $inFile->getHeaders();
  #$row = $inFile->getNextRow();
  $nfields = scalar(@$headers);
  print "Table has $nfields fields.\n\n";
  for ($i = 0 ; $i < $nfields ; $i++)
    {
      $colInfo->[$i]{TYPE} = "Unknown";
      $colInfo->[$i]{DIFS} = 0;
      $colInfo->[$i]{VALUES} = {};
      $colInfo->[$i]{NAME} = $headers->[$i];
      $colInfo->[$i]{HASUNKNOWNS} = 0;
    }
  
  while (!$inFile->eof()) 
    {  
      #$line = $inFile->getNext();
      #$line = Durin::Utilities::StringUtilities::removeCtrlMEnter($line);
      #if (!($line eq ""))
      #{
      #@array = split(/,/,$line);
      #$row = \@array;
      $row = $inFile->getNextRow();
      processLine($row,$colInfo);
      #}
    }
  
  #my $table = Durin::Metadata::Table->new();
  my $tableSchema;
  #if (defined $class)
  #  {
  #    $tableSchema = Durin::Classification::ClassedTableSchema->new();
  #    $tableSchema->setClassByPos($class);
  #  }
  #else
  #  {
      $tableSchema = Durin::Data::TableSchema->new();
  #  }
  
  
  for ($i = 0; $i < $nfields ; $i++)
    {
      my ($att,$attType);
      $att = Durin::Metadata::Attribute->new();
      $att->setName($colInfo->[$i]{NAME});
      if ($colInfo->[$i]{DIFS} < $max)
	{
	  $attType = Durin::Metadata::ATCategorical->new();
	  my $temp = $colInfo->[$i]{VALUES};
	  $attType->setValues([keys %$temp]);
	  # print (keys %$temp);
	}
      else
	{
	  $attType = Durin::Metadata::ATCreator->create($colInfo->[$i]{TYPE});
	}
      if ($colInfo->[$i]{HASUNKNOWNS} == 1)
	{
	  $attType->setHasUnknowns(1);
	  #print "Att $i has unknowns\n";	      
	}
      else
	{
	  #print "Att $i has no unknowns\n";
	}
      $att->setType($attType);
      $tableSchema->addAttribute($att);
    }
  #$table->setSchema($tableSchema);
  return $tableSchema;
}

sub processLine
  {
    my ($row,$colInfo) = @_;
    
    my($i,$value);
    
    $i = 0;
    #print @$row;
    #print "Line:", join(",",@$row),"\n";
    foreach $value (@$row)
      {
	($colInfo->[$i]{TYPE},$colInfo->[$i]{HASUNKNOWNS}) = @{tipify($colInfo->[$i]{TYPE},$colInfo->[$i]{HASUNKNOWNS},$value)};
	if ($colInfo->[$i]{VALUES}{$value})
	  {
	    $colInfo->[$i]{VALUES}{$value}++;
	  }
	else
	  {	
	    $colInfo->[$i]{VALUES}{$value} = 1;
	    $colInfo->[$i]{DIFS}++;
	  }
	$i++;
      }
  }

sub tipify
{  
  my($previoustype,$previousUnknown,$value) = @_;
  
  my $Type = $previoustype;
  my $Unknown = $previousUnknown;
  
  if ($value eq "?")
    {
      $Unknown = 1;
    }
  #print "PreviousType: $previoustype\n";
  
  if ($previoustype eq "Unknown")
    {
      if (Durin::Utilities::StringUtilities::isnum($value))
	{
	  $Type = "Number";
	}
      else
	{
	  if (Durin::Utilities::StringUtilities::isDate($value))
	    {
	      $Type = "Date";
	    }
	  else
	    {
	      if ($value ne "?")
		{
		  $Type = "String";
		}
	    }
	}
    }
  else 
    {
      if ($previoustype eq "Number")
	{
	  if ((!Utilities::StringUtilities::isnum($value)) && ($value ne "?"))
	    {  
	      $Type = "String";
	    }
	}
      else
	{
	  if ($previoustype eq "Date")
	    {
	      if ((!Utilities::StringUtilities::isDate($value)) && ($value ne "?"))
		{  
		  $Type = "String";
		}
	    }
	}
    }
  return [$Type,$Unknown];
}

return 1;

