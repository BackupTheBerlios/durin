package Durin::PP::Transform::Attribute;

use Durin::PP::Transform::ATIdentity;
use Durin::PP::Transform::ATDateToNumber;
use Durin::PP::Transform::ATValueMap;

sub getTransform
  {
    my ($class,$name) = @_;
    
    if ($name eq "Identity")
      {
	return Durin::PP::Transform::ATIdentity->new();
      }
    
    if ($name eq "DateToNumber")
      {
	return Durin::PP::Transform::ATDateToNumber->new();
      }
    if ($name eq "ValueMap")
      {
	return Durin::PP::Transform::ATValueMap->new();
      }
    die "Unknown attribute transformation $name\n";
  }

1;
