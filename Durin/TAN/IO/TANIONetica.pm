package Durin::TAN::IO::TANIONetica;

use Durin::FlexibleIO::IOHandler;

@ISA = (Durin::FlexibleIO::IOHandler);
$IO_CLASS = "Durin::TAN::TAN";
$IO_FORMAT = "Netica";

use strict;

use Durin::TAN::TAN;
#use Durin::FlexibleIO::ExtInfo;
#use Durin::Metadata::Table;
use Durin::Utilities::StringUtilities;

sub write
{
    my ($class,$disp,$TAN) = @_;
    print $disp "// ~->[DNET-1]->~\r\n\r\n";
    print $disp "// File created by an unlicensed user using Netica 1.12\r\n";
    print $disp "// on Mar 08, 1999 at 16:01:19.\r\n\r\n";

    print $disp "bnet TAN {\r\n";

    my $schema = $TAN->getSchema();
    my $PA = $TAN->getProbApprox();

    # Write the node class
    
    my $classAttNumber = $schema->getClassPos();
    my $classAtt = $schema->getAttributeByPos($classAttNumber);
    my @classStates = @{$classAtt->getType()->getValues()};
    my $className = $classAtt->getName();

    # We delete undesired attributes and states names with spaces in the middle

    my $printableClassName = stringCleaning($className);
    print $printableClassName,"\n";
    my $i = 0;
    my @printableClassStates = ();
    foreach my $state (@classStates)
      {
	my $printableState = stringCleaning($state);
	push @printableClassStates,$printableState;
	print "$printableState\n";
	$i++;
      }


    print $disp "\tnode $printableClassName {\r\n";
    print $disp "\tkind = NATURE;\r\n";
    print $disp "\tdiscrete = TRUE;\r\n";
    print $disp "\tchance = CHANCE;\r\n";
    print $disp "\tstates = (",join(",",@printableClassStates),");\r\n";
    print $disp "\tparents = ();\r\n";
    print $disp "\tprobs = \r\n";
    print $disp "\t\t(";
    my $first = 1;
    foreach my $classState (@classStates)
      {
	if (!$first)
	  {
	    print $disp ",";
	  }
	else
	  {
	    $first = 0;
	  }
	print $disp $PA->getPClass($classState);
      }
    print $disp ");\r\n";
    print $disp "\tnumcases = 1;\r\n";
    print $disp "\twhenchanged = 921058119;\r\n";;
    print $disp "\t};\r\n";
    
    # Now for each node, we write it in the file.

    #if (0)
    #  {
    my $tree = $TAN->getTree();
    my @nodes = @{$tree->getNodes()};
    #    print join(",",@nodes),"\n";
    my @parents;
    foreach my $node (@nodes)
      {	
	my $attrib = $schema->getAttributeByPos($node);
	my $nodeName = $attrib->getName();

	my $printableNodeName = stringCleaning($nodeName);

	print $disp "\tnode $printableNodeName {\r\n";
	print $disp "\tkind = NATURE;\r\n";
	print $disp "\tdiscrete = TRUE;\r\n";
	print $disp "\tchance = CHANCE;\r\n";
	
	# We take the states of this node from the schema
	
	my @nodeStates = @{$attrib->getType()->getValues()};
	my @newNodeStates = ();
	my $i = 0;
	foreach my $nodeState (@nodeStates)
	  { 
	    if ($nodeState eq "?")
	      {
		$newNodeStates[$i] = "Unknown";
	      }
	    else
	      {
		$newNodeStates[$i] = $nodeState;
		$newNodeStates[$i] = stringCleaning($newNodeStates[$i]);
	      }
	    $i++;
	  }
	print $disp "\tstates = (",join(",",@newNodeStates),");\r\n";
	
	# We take the parents
	
	print $disp "\tparents = ($printableClassName";
	
	my @parents = @{$tree->getParents($node)};
	#print "Node: $node. Parents:",join(",",@parents),"\n";
	my @parentNames = ();
	my $hasAParent = ($#parents == 0);
	my @parentStates = ();
	my $parent;
	if ($hasAParent)
	  {
	    $parent = $parents[0];
	    my $parentAtt = $schema->getAttributeByPos($parent);
	    @parentStates = @{$parentAtt->getType()->getValues()};
	    my $parentName = $parentAtt->getName();
	    my $printableParentName = stringCleaning($parentName); 
	    print $disp ",$printableParentName";
	  }
	
	print $disp ");\r\n";
	
	# The probabilities
	
	print $disp "\tprobs = (";

	my $firstClass = 1;
	foreach my $classState (@classStates)
	  {
	    if ($firstClass)
	      {
		print $disp "(";
		$firstClass = 0;
	      }
	    else
	      {
		print $disp ",\r\n\t\t(";
	      }
	    if ($hasAParent)
	      {
		my $firstParent = 1;
		foreach my $parentState (@parentStates)
		  {
		    if ($firstParent)
		      {
			$firstParent = 0;
			print $disp "(";
		      }
		    else
		      {
			print $disp ",\r\n\t\t(";
		      }
		   
		    my $firstState = 1;
		    foreach my $nodeState (@nodeStates)
		      {
			if ($firstState)
			  {
			    $firstState = 0;
			  }
			else
			  {
			    print $disp ",";
			  }
			print $disp $PA->getPYCondXClass($classState,$parent,$parentState,$node,$nodeState);
		      }
		    print $disp ")";
		  }
	      }
	    else
	      {
		my $first = 1;
		foreach my $nodeState (@nodeStates)
		  {
		    if ($first)
		      {
			$first = 0;
		      }
		    else
		      {
			print $disp ",";
		      }
		    print $disp $PA->getPXCondClass($classState,$node,$nodeState)
		  }
	      }
	    print $disp ")";
	  }
	print $disp ");\r\n";
	print $disp "\t};\r\n";
      }
#    } #if 0
    print $disp "\t};\r\n";
  }

sub stringCleaning
  {
    my ($string) = @_;

    # Replace ranges with its correct representation

    $string =~ s/(\d+).*\d*-(\d+).*\d*/Between_$1_and_$2/;

    $string =~ tr/[\ \-\.]/\_/;

    $string =~ s/^\?$/Unknown/;
    $string =~ s/^\?.+/Unknown_/;
    $string =~ s/\?.+/_Unknown_/g; 
    $string =~ s/\?$/_Unknown/g;

    $string =~ s/^\<\=/SmallerOrEqualThan\_/; 
    $string =~ s/\<\=/\_SmallerOrEqualThan\_/g;
    
    $string =~ s/^\</SmallerThan\_/; 
    $string =~ s/\</\_SmallerThan\_/g;

    $string =~ s/^\>\=/BiggerOrEqualThan\_/; 
    $string =~ s/\>\=/\_BiggerOrEqualThan\_/g;

    $string =~ s/^\>/BiggerThan\_/; 
    $string =~ s/\>/\_BiggerThan\_/g;

    $string =~ s/^(\d)/x$1/;
    if (! m/^\w.*/)
      {
	$string = "x".$string;;
      }
    
    return substr($string,0,30);
  }

sub read
  {
    my ($class,$disp) = @_;
    
    die "NYI\n";
  }

1;
