
package Durin;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.01;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Durin - A Perl data mining framework

=head1 SYNOPSIS

  use Durin;
  
  This POD contains the structure and a short introduction to the Durin DM framework

=head1 DESCRIPTION

The objective of the framework is to provide an extensible approach to ease the implementation of data mining processes. The framework has been up to now implemented in Perl. The framework is based in components that are implemented as Perl objects. We review here what the different modules contain. 

=head2 Infrastructure:

=over

=item Basic

Contains some common roles as: MIManager (the manager of multiple inheritance) and NamedObject (a orthogonal class that implements a named object).

=item Components

Contains the different kind of components that are contained into the framework. These are: Data, Metadata and Process.

=item FlexibleIO

Contains the infrastructure for flexible input/output. This infrastructure is based in decomposing the I/O problem into three dimensions: A device, a format and an object. For each different device and format we have a IOHandler. An object should inherit from Externalizable to be part of the framework. The IORegistry contains the different Handlers and can be accessed at run-time. The user of the framework should use FlexibleIO::System to have access to these functionality.

=item Utilities

Contains common utilities for handling strings and math routines.

=item Algorithms

Contains common algorithms (actually only contains Kruskal and Gabow algorithms for finding minimum spanning trees).

=item DataStructures

Contains implementations of commonly used data structures as ordered lists, graphs, digraphs, ...

=head2 Functionality

=item Data

Contains the Data component hierarchy

=item Model

Contains the different models that the system can induce. The processes used to induce them are in Process.

=item Metadata

Contains the Metadata component hierarchy 

=item Process

Contains the different processing methods provided by the framework. This includes the learning algorithms. Most of the functionality of the framework relies here.

=item PP

Contain the preprocessing processes. We can find a simple framework for dealing with transformation in there. Discretization should go in there in the future.

=item scripts 

Contains useful short scripts that can be used as utilities as well as as examples of usage of the framework.

=head1 PREREQUISITES

You should install:

=item expat

XML parser 
http://www.jclark.com/xml/expat.html

=item XML::DOM

=item XML::Generator

=item PDL 

The Perl Data Language 
http://pdl.perl.org/

= item Class::MethodMaker

=head1 USAGE

TBD

=head1 BUGS

TBD

=head1 SUPPORT

TBD

=head1 AUTHOR

	Jesus Cerquides Bueno
	cerquide@iiia.csic.es
	http://www.iiia.csic.es/~cerquide

=head1 COPYRIGHT

Copyright (c) 2001 Jesus Cerquides Bueno. All rights reserved.
This program is free software licensed under the...

	The GNU Lesser General Public License (LGPL)
	Version 2.1, February 1999

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1; #this line is important and will help the module return a true value
__END__


