# Implements the device to load Mineset files.

package Durin::FlexibleIO::MinesetPair;

use Durin::FlexibleIO::Device;

@ISA = (Durin::FlexibleIO::Device);

use strict;

use Durin::FlexibleIO::IORegistry;
use Durin::FlexibleIO::File;

sub new_delta
  {
    my ($class,$self) = @_;
    
    $self->{NAMES_FILE} = undef;
    $self->{ALL_FILE} = undef;
    $self->{FILE_SELECTED} = undef;
  }

sub clone_delta
  {
    my ($class,$self,$source) = @_;
   
    die "Durin::FlexibleIO::MinesePair clone NYI\n";
    #$self->setNamesFileName($source->getNamesFileName());
    #$self->setAllFileName($source->getAllFileName());
    #$self->setFileSelected($source->getFileSelected());
  }

#sub init
#  {
#    my ($self,$string) = @_;
    
#    my @array = split(/ /,$string);
    #print "After splitting:",join(",",@array),"\n";
#    $self->setFileName($array[0]);
#  }

sub setNamesFileName
  {
    my ($self,$filename) = @_;
    
    my $file = Durin::FlexibleIO::File->new();
    $file->setFileName($filename);
    $self->{NAMES_FILE} = $file;
  }

sub getNamesFileName
  {
    my ($self) = @_;
    
    return $self->{NAMES_FILE}->getFileName();
  }

sub setAllFileName
  {
    my ($self,$filename) = @_;
    
    my $file = Durin::FlexibleIO::File->new();
    $file->setFileName($filename);
    $self->{ALL_FILE} = $file;
  }

sub getAllFileName
  {
    my ($self) = @_;
    
    return $self->{ALL_FILE}->getFileName();
  }

sub useNames
  {
    my ($self) = @_;
    
    return $self->{FILE_SELECTED} = $self->{NAMES_FILE};
  }

sub useAll
  {
    my ($self) = @_;
    
    return $self->{FILE_SELECTED} = $self->{ALL_FILE};
  }

sub open
  {
    my ($self,$access) = @_;
    
    $self->{FILE_SELECTED}->open($access);
  }

sub seek
  {
    my ($self,$p1,$p2) = @_;
    
    $self->{FILE_SELECTED}->seek($p1,$p2);
  }

sub close
  {
    my ($self) = @_;
    
    $self->{FILE_SELECTED}->close();
  }

sub eof
  {
    my ($self) = @_;
    
    return $self->{FILE_SELECTED}->eof();
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
    
    print {$self->{FILE_SELECTED}} @string;
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
    
    return $self->{FILE_SELECTED}->getline();
  }

#sub makestring 
#  {
#    my ($self) = @_;
#    
#    my $class = "Durin::FlexibleIO::File";
#    return $class." ".$self->getFileName();
#  }

1;
