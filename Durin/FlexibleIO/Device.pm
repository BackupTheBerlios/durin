# This is the parent class of all Devices that can be used with the framework.

package Durin::FlexibleIO::Device;

use base Durin::Basic::MIManager;

#@ISA = (Durin::Basic::MIManager);

use strict;

sub new_delta
{
    my ($class,$self) = @_;
}

sub clone_delta
{
    my ($class,$self,$source) = @_;
}

# Initializes a device from a device description in a string

sub init { die "Pure Virtual\n";}

# Creates a device description for this device

sub makestring() { die "Pure Virtual\n";}
sub open { die "Pure Virtual\n";}
sub close { die "Pure Virtual\n";}
sub print { die "Pure Virtual\n";}
sub read { die "Pure Virtual\n";}
sub getline { die "Pure Virtual\n";}
sub eof { die "Pure Virtual\n"; }
sub seek { die "Pure Virtual\n"; }

1;
