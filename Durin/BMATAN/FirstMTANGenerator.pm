#CARE!!!!! PROBABLY OBSOLETE

# Runs Kruskal for finding a k maximum weighted spanning tree

package Durin::BMATAN::FirstMTANGenerator;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::BMATAN::MultipleTANGenerator;
use Durin::BMATAN::FirstMTreeGen;

sub new_delta
{
    my ($class,$self) = @_;
    
    $self->{MTANG} = Durin::BMATAN::MultipleTANGenerator->new();
    #   $self->{METADATA} = undef; 
}

sub clone_delta
{ 
    my ($class,$self,$source) = @_;
    
 #   $self->setMetadata($source->getMetadata()->clone());
}

sub run
{
  my ($self) = @_;
  
  my $MTANG = $self->{MTANG};
  {
    my $input = $self->{INPUT};
   
    $input->{MTREEGEN} = Durin::BMATAN::FirstMTreeGen->new();
    $MTANG->setInput($input);
  }
  $MTANG->run(); 
  my $MT = $MTANG->getOutput();
  $self->setOutput($MT);
}

1;
