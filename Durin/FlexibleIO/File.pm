#Implements the device File

package Durin::FlexibleIO::File;

use Durin::FlexibleIO::Device;
use IO::File;
use Durin::FlexibleIO::IORegistry;

@ISA = (Durin::FlexibleIO::Device);

use strict;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{EXT_ACCESS} = undef;
    $self->{EXT_FILENAME} = undef;
  }

sub clone_delta
  {
    my ($class,$self,$source) = @_;
    
    $self->setAccess($source->getAccess());
    $self->setFileName($source->getFileName());
  }

sub init
  {
    my ($self,$string) = @_;
    
    my @array = split(/ /,$string);
    #print "After splitting:",join(",",@array),"\n";
    $self->setFileName($array[0]);
  }

sub setAccess
  {
    my ($self,$access) = @_;
    
    $self->{EXT_ACCESS} = $access;
  }

sub getAccess
  {
    my ($self) = @_;
    
    return $self->{EXT_ACCESS};
  }

sub setFileName
  {
    my ($self,$filename) = @_;
    
    $self->{EXT_FILENAME} = $filename;
  }

sub getFileName
  {
    my ($self) = @_;
    
    return $self->{EXT_FILENAME};
  }

sub open
  {
    my ($self,$access) = @_;
    
    if (!$access)
      {
	$access = "<";
      }
    $self->{FILE_HANDLER} = new IO::File;
    
    my $fileName = $self->getFileName();
    
    my $result = $self->{FILE_HANDLER}->open($access.$fileName);
    if (!$result)
      {
	print "***ERROR::Unable to open file ",$fileName,"\n";
      }
    return $result;
  }

sub seek
  {
    my ($self,$p1,$p2) = @_;
    
    seek $self->{FILE_HANDLER},$p1,$p2;
  }

sub close
  {
    my ($self) = @_;
	    
    $self->{FILE_HANDLER}->close();
  }

sub eof
  {
    my ($self) = @_;
    
    return $self->{FILE_HANDLER}->eof();
  }

#sub write
#  {
#    my ($self,$object) = @_;
#    
#    my $IOHandler = Durin::FlexibleIO::IORegistry->get($self->getDataType(),$self->getFormat(),1);
#    $IOHandler->write($self,$object);
#}

sub print
  {
    my ($self,@string) = @_;
    
    print {$self->{FILE_HANDLER}} @string;
  }

#sub read
#  {
#    my ($self) = @_;
    
    #print "Calling read on:",$self->getDataType()," ",$self->getFormat(),"\n";
#    my $IOHandler = Durin::FlexibleIO::IORegistry->get($self->getDataType(),$self->getFormat(),1);
#    return $IOHandler->read($self);   
#  }

sub getline
  {
    my ($self) = @_;
    
    return $self->{FILE_HANDLER}->getline();
  }

sub makestring 
  {
    my ($self) = @_;
    
    my $class = "Durin::FlexibleIO::File";
    return $class." ".$self->getFileName();
  }

1;
