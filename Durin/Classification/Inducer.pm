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

sub getCountingTable {
  my ($self) = @_;

  if (defined $self->{INDUCER}) {
    return $self->{INDUCER}->getCountingTable();
  } else {
    return undef;
  }
}

sub run($)
{
  die "Pure virtual Durin::Classification::Inducer::run\n";
}

# Returns a hash with inducer details
sub getDetails($) {
  my ($class) = @_;

  my $details = {}; 
  return $details;
}

1;
