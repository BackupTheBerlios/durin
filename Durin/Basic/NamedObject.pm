# This package is a base which provides an object with a name.

package Durin::Basic::NamedObject;

=head1 NAME

  Durin::Basic::NamedObject - provides support for named objects

=head1 DESCRIPTION

=over

This package is a base which provides an object with a name

=cut

use Durin::Basic::MIManager;

@ISA = (Durin::Basic::MIManager);

sub new_delta 
{
    my ($class,$self) = @_;
    
    $self->{NAME} = undef;
}

sub clone_delta($$)
{
    my ($class,$self,$source) = @_;
 
    #print "The name cloned is:".$source->getName()."\n";
    
    setName($self,$source->getName());
}

sub init($$)
{
    my ($class,$self) = @_;

    $self->{NAME} = undef;
}

=item setName/getName

  Sets/Gets the name of the object.

=cut
sub setName($$)
{
    my ($self,$name) = @_;
    
    $self->{NAME} = $name;
}

sub getName($)
{
    my $self = shift;
		
    return $self->{NAME};
}

1;

