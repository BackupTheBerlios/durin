package Durin::Basic::MIManager;

=head1 NAME

  Durin::Basic::MIManager - Multiple Inheritance Manager.

=head1 SYNOPSIS

  The object defines how multiple inheritance should be handled. 

=head1 DESCRIPTION

This multiple inheritance manager defines a Perl idiom to create and clone Perl objects using multiple inheritance. By default, Perl allows for multiple inheritance, but when you call the constructor new it is only called in the derived class or searched for in the inheritance tree if if does not exist in the derived class. What MIManager offers is an idiom where every object in the hierarchy has two special methods "new" and "clone". The code for these two methods resides in MIManager and they are implemented by means of two "hook methods" "new_delta" and "clone_delta" into each class, that "new" and "clone" take care to call in the addecuate order. Hence, every object derived from MIManager you should have: 
=over
=item a sub new_delta
=item a sub clone_delta (if the object has to be clonable)
=back
even if they appear completely empty.

=cut

@ISA = ();

use strict;

=item new($class)

  This function allows us to have constructors. These constructors are called following a depth first order in the is-a hierarchy. For each class that we want to be constructible we need to provide a "new_delta" function and take care that this function initializes whatever is added by its concrete class.


=cut
sub new 
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless ($self,$class);
    no strict;
    new_rec $class ($self);
    
    return $self;
}

=item clone($class)

  This function allows us to have a deep-cloning language. Clones are called following a depth first order in the is-a hierarchy. For each class that we want to be cloneable we need to provide a "clone" function and take care that this function clones whatever is added by its concrete class.

=cut

sub clone
{ 
    my $source = shift;
    my $class = ref($source) || $source;
    my $self = $class->new();
    
    no strict;
    clone_rec $class ($self,$source);
    
    return $self;
}

sub clone_rec($$$)
{
    my ($class,$self,$source) = @_;
    
    my ($module);
    no strict;
    foreach $module (@{$class."::ISA"})
    {
	clone_rec $module ($self,$source);
    }    
    clone_delta $class ($self,$source);
}

sub new_rec
{
    my ($class,$self) = @_;
    my ($module);

    no strict;
    foreach $module (@{$class."::ISA"})
    {
	new_rec $module ($self);
    } 
    new_delta $class ($self);
}

# This contains the initialization of the object.

sub new_delta
{
    # my ($class,$self) = @_;
}

sub clone_delta
{
    # my ($class,$self,$source) = @_;
}

1;









