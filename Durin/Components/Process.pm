# This package is the base for all process components in the system.

package Durin::Components::Process;

=head1 NAME

  Durin::Components::Process - root of all processes.

=head1 SYNOPSIS

  Contains the functions common to all the process components.

=head1 DESCRIPTION

=over

=cut

# This has to be continued further.

use base Durin::Basic::MIManager;

#@ISA = (Durin::Basic::MIManager);

use strict;

sub new_delta 
{  
    my ($class,$self) = @_;

    $self->{INPUT} = undef;
    $self->{OUTPUT} = undef;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
    
    $self->setInput($source->getInput());
    $self->setOutput($source->getOutput());
}

sub setInput($$)
{
    my ($self,$input) = @_;

    $self->{INPUT} = $input;
}

sub getInput($)
{
    my ($self) = @_;

    return $self->{INPUT};
}

sub setOutput($$)
{
    my ($self,$output) = @_;

    $self->{OUTPUT} = $output;
}

sub getOutput($)
{
    my ($self,$output) = @_;

    return $self->{OUTPUT};
}

sub run($)
{
    die "Components::Process::run is pure virtual";
}

1;
