package Durin::FlexibleIO::IORegistry;

use strict;

my $registry = {};

sub register
  {
    my ($class,$data_class,$format,$object) = @_;
    
    $registry->{$data_class}->{$format} = $object;
  }

sub get
  {
    my ($class,$data_class,$format,$inheritance) = @_;
    
    my ($IOHandler,@list,$ascendant,$i);
    
    $IOHandler = $registry->{$data_class}->{$format};
    if ((!$IOHandler) && $inheritance)
      {
	#print "Looking for superclasses\n";
	# If we haven't find an adecuate handler we go down the ISA relation bread first.
	no strict;
	@list = @{$data_class."::ISA"};
	$i = 0;
	while ((!$IOHandler) && ($i <= $#list))
	  {    
	    #print "List:", @list,"\n";
	    $ascendant = $list[$i];
	    $IOHandler = Durin::FlexibleIO::IORegistry->get($ascendant,$format,0);
	    @list = (pop(@list),@{$ascendant."::ISA"});
	  }
    }
    return $IOHandler;
  }

1;
