package Durin::Utilities::StringUtilities;

sub removeEnter
{
    my ($string) = @_;
	
    $string =~ /^((?:.|\n)*)\n$/;
    
    return $1;
}

sub removeCtrlMEnter
{
    my ($string) = @_;
	
    $string =~ /^(.*)\r\n$/;
    
    return $1;
}

# Returns true if the string is 0 or more blank spaces
sub isSpaces
{
    my($value) = @_;

    return ($value =~ /^[ ]*$/);
}

sub isnum
{
    my($value) = @_;

    return ($value =~ /^[+-]?[0-9]+[.]?[0-9]*[ ]*$/);
}

sub isMinesetComment
{
    my($value) = @_;

    return ($value =~ /^\|.*$/);
}

sub isDate
  {
    my($value) = @_;
    
    return ($value =~ /^[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9][0-9]$/);
  }

1;
