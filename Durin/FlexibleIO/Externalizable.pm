package Durin::FlexibleIO::Externalizable;

# It externalizes an object i,e. puts it into a given dispositive with a given format.

use base Durin::Basic::MIManager;

#@ISA = (Durin::Basic::MIManager);

use Durin::FlexibleIO::IORegistry;
use Durin::FlexibleIO::IOHandler;
use strict;

#sub new_delta
#  {
#    my ($class,$self) = @_;
#    
#  }

#sub clone_delta
#  { 
#    my ($class,$self,$source) = @_;
#  }

# This is a static function
sub read
  {
    my ($class,$disp,$format,$inheritance) = @_;
    
    if (!defined($format))
      {
      $format = "Standard";
    }
    if (!defined($inheritance))
      {
	$inheritance = 1;
      }
    
    #print "Looking for : $class,$format,$inheritance\n";
    my $IOHandler = Durin::FlexibleIO::IORegistry->get($class,$format,$inheritance);
    #print $IOHandler,"\n";
    my $table = $IOHandler->read($disp);
    return $table;
  }

# This one is not static
sub write
  {
    my ($self,$disp,$format,$inheritance) = @_;
    
    my $hasBeenOpened = 0;
    if (!defined($disp))
      {
	$disp = $self->getMetadata()->getOutExtInfo();
	$disp->open();
	$hasBeenOpened = 1;
      }
    if (!defined($format))
      {
	$format = "Standard";
      }
    if (!defined($inheritance))
      {
	$inheritance = 1;
      }
    
    my $class = ref($self);
    #print "Looking for : $class,$format,$inheritance\n";
    my $IOHandler = Durin::FlexibleIO::IORegistry->get($class,$format,$inheritance);
    #print $IOHandler,"\n";
    my $result = $IOHandler->write($disp,$self);
    if ($hasBeenOpened)
      {
	$disp->close();
      }
    return $result;
  }

1;
