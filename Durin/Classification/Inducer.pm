package Durin::Classification::Inducer;

use Durin::Components::Process;
use Durin::Basic::NamedObject;

@ISA = qw(Durin::Components::Process Durin::Basic::NamedObject);

use strict;

sub new_delta
{
    my ($class,$self) = @_;
    
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run($)
{
  die "Pure virtual Durin::Classification::Inducer::run\n";
}

1;
