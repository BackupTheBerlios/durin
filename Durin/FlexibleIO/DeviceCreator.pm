# Factory for the different devices

package Durin::FlexibleIO::DeviceCreator;

use strict;
use Durin::FlexibleIO::Device;

# Creates a device from a device description in a string
# Format of the string: deviceClass deviceInitDescription

sub create 
  {
    my ($self,$string) = @_;
    
    #print "Creating device: $string\n";
    $_ = $string;
    my @list = /(.*) (.*)/;
    
    my $deviceClass = $list[0];
    no strict;
    eval("require $deviceClass");
    import $deviceClass;
    my $device = new $deviceClass ();
    
    $device->init($list[1]);
    return $device;
  }

1;
