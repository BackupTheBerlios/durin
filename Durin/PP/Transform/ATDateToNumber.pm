package Durin::PP::Transform::ATDateToNumber;

use Durin::PP::Transform::AttributeTransform;

@ISA = (Durin::PP::Transform::AttributeTransform);

use strict;

use Date::Calc;

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

sub transform
  {
    my ($self,$value) = @_;
    
    if (Durin::Metadata::ATDate->isUnknown($value))
      {
	return $value;
      }
    else
      {
	my $day = substr($value,0,2);
	my $month = substr($value,3,2);
	my $year = substr($value,6,4);
	return Date::Calc::Date_to_Days($year,$month,$day);
      }
  }

1;
