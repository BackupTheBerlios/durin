package Durin::Math::Functions;

use strict;

# This functions calculates a hyperbolic tangent but sharpened as $alfa -> 0

sub Reification
  {
    my ($function,$argPos) = @_;
    
    return 
      sub
	{
	  my ($argValue) = @_;
	  
	  #print "Executing A\n";
	  return sub
	    {
	      my @otherArgs = @_;
	      
	      #print "Executing B\n";
	      splice(@otherArgs,$argPos-1,0,$argValue);
	      return &$function(@otherArgs)
	    }
	}
  }

sub AlfaReifiedSharpenedHyperbolicTangent
  {
    my ($alfa) = @_;

    my $reifiedFunc = Reification(\&SharpenedHyperbolicTangent,2);
    return &$reifiedFunc($alfa);
  }


# This functions calculates a hyperbolic tangent but sharpened as $alfa -> 0

sub SharpenedHyperbolicTangent
  {
    my ($x,$alfa) = @_;

    my $exp1 = exp ($x/$alfa);
    my $exp2 = exp (-$x/$alfa);

    return (($exp1-$exp2)/($exp1+$exp2));
  }

1;
