package Durin::Classification::ClassedTableSchema;

use Durin::Data::TableSchema;

@ISA = (Durin::Data::TableSchema);

use strict;

use Durin::Metadata::Attribute;

sub new_delta 
{ 
    my ($class,$self) = @_;
  
    $self->{CLASS} = undef;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
    
    #print "Calling Durin::Classification::ClassedTableSchema\n";
    $self->setClassByPos($source->getClassPos());
}

sub setClassByName($$)
{
    my ($self,$class) = @_;

    die "Durin::Data::ClassedTable->setClassByName NYI\n";
}

sub setClassByPos($$)
{
    my ($self,$class) = @_;

    $self->{CLASS} = $class;
}

sub getClassPos($)
{
    my $self = shift;
    
    return $self->{CLASS};
} 

sub makestring($)
{
    my $self = shift;
    
    return $self->SUPER::makestring();
}

1;
