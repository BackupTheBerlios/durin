# This is the basis of the externalization system.
# Has four main fields:
# - DataType is the class of what is externalized
# - Format is the format used 
# - Device is the device used

package Durin::FlexibleIO::ExtInfo;

#use Durin::Basic::MIManager;

#@ISA = (Durin::Basic::MIManager);
use base Durin::Basic::MIManager;
use strict;
use Durin::FlexibleIO::DataTypeMappingRegistry;

#use Durin::FlexibleIO::IORegistry;
use Durin::FlexibleIO::DeviceCreator;

sub new_delta
{
    my ($class,$self) = @_;

    $self->{EXT_DATA_TYPE} = undef;
    $self->{EXT_FORMAT} = undef;
    $self->{EXT_DEVICE} = undef;
  }

sub clone_delta
  {
    my ($class,$self,$source) = @_;
    
    $self->setDataType($source->getDataType());
    $self->setFormat($source->getFormat());
    $self->setDevice($source->getDevice());
  }

sub create
  {
    my ($class,$string) = @_;
    
    #print "ExtInfo string: $string\n";

    $_ = $string;
    my @array = /(.*) (.*) \[(.*)\]/;
    
    #print "After splitting:",join(",",@array),"\n";

    my $extInfo = new $class;
    $extInfo->setDataType($array[0]);
    $extInfo->setFormat($array[1]);
    my $device = Durin::FlexibleIO::DeviceCreator->create($array[2]);
    #print $device,"\n";
    $extInfo->setDevice($device);
    
    return $extInfo;
  }

sub setDataType
  {
    my ($self,$type) = @_;
    
    $self->{EXT_DATA_TYPE} =  Durin::FlexibleIO::DataTypeMappingRegistry->getMapping($type);
  }  

sub getDataType
  {
    my ($self) = @_;
 
    return $self->{EXT_DATA_TYPE};
  }  

sub setFormat
  {
    my ($self,$format) = @_;
 
    $self->{EXT_FORMAT} = $format;
  }

sub getFormat
  {
    my ($self) = @_;
    
    return $self->{EXT_FORMAT};
  }

sub setDevice
  {
    my ($self,$device) = @_;
    
    $self->{EXT_DEVICE} = $device;
  }

sub getDevice
  {
    my ($self) = @_;
    
    return $self->{EXT_DEVICE};
  }


sub makestring
  {
    my ($self) = @_;
    
    my $device = $self->getDevice();
    #print "Device: $device\n";
    my $deviceString = $device->makestring();
    #print "Device string: $deviceString\n";
    return $self->getDataType()." ".$self->getFormat()." [".$deviceString."]";
  }

sub write
  { 
    my ($self,$data) = @_;
    
    my $device = $self->getDevice();
    $device->open(">");
    $data->write($device,$self->getFormat());
    $device->close();
  }

sub read 
  {
    my ($self) = @_;
    
    my $device = $self->getDevice();
    my $dataType = $self->getDataType();
    $device->open("<");
    my $data = $dataType->read($device,$self->getFormat());
    $device->close();
    return $data;
  }

1;
