
package Durin::BMATAN;
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

Durin::BMATAN - Contains Bayesian Model Averaging for Tree Augmented Naive-Bayes algorithms 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 BMACCFTANInducer

Provides a BMATANInducer using a simple alternative to MultipleTANGenerator (Gabow algorithm) using the simple tree generator contained in FirstMTANGenerator and FirstMTreeGen.

=head2 BMACoherentCoherentTANInducer BMAFGGTANInducer  BMAFrequencyCoherentTANInducer

Different BMA TAN Inducers with different probability estimates. All of them simply set parameters in BMATANInducer.

=head2 BMATANInducer

Main module, implementing a BMA TAN Inducer. 

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

