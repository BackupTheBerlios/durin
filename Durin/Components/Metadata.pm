package Durin::Components::Metadata;

use Durin::Basic::NamedObject;

@ISA = (Durin::Basic::NamedObject);

use strict;
use Durin::FlexibleIO::ExtInfo;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{IN_EXT_INFO} = undef;
    $self->{OUT_EXT_INFO} = undef;
  }

sub clone_delta
  {
    my ($class,$self,$source) = @_;
    
    my $extInfo = $source->getInExtInfo();
    if ($extInfo)
      {
	$self->setInExtInfo($extInfo->clone());
      }
    $extInfo = $source->getOutExtInfo();
    if ($extInfo)
      {
	$self->setOutExtInfo($extInfo->clone());
      }
  }
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# I think this is not longer in work. I skip it. Maybe it should be uncommented afterwards

#sub read($$)
#  {
#    my ($class,$extInfo) = @_;
#    
#    $class->read_delta($extInfo);
#  }

#sub read_delta($$)
#  {
#    my ($self,$extInfo) = @_;
#    
#    $self->setExtInfo(Durin::FlexibleIO::ExtInfo->read($extInfo));
#  }

#sub write($$)
#  { 
#    my ($self,$extInfo) = @_;
#    
#    $self->write_delta($extInfo);
#  }

#sub write_delta($$)
#  { 
#    my ($self,$extInfo) = @_;
#    
#    $self->getExtInfo()->write($extInfo);;
#  }

sub setInExtInfo
  {
    my ($self,$extInfo) = @_;
    
    $self->{IN_EXT_INFO} = $extInfo;
  }

sub getInExtInfo
  {  
    my ($self) = @_;
    
    return $self->{IN_EXT_INFO};    
  }

sub setOutExtInfo
  {
    my ($self,$extInfo) = @_;
    
    $self->{OUT_EXT_INFO} = $extInfo;
  }

sub getOutExtInfo
  {  
    my ($self) = @_;
    
    return $self->{OUT_EXT_INFO};    
  }
