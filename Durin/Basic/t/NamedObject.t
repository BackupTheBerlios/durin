# t/NamedObject.t;  Durin::Basic::NamedObject basic test

$|++; 
print "1..1\n";

my($test) = 1;

# 2 load
use Durin::Basic::NamedObject;

my $new = Durin::Basic::NamedObject->new();
$new->setName("aWeirdName123¿¿??ña");
my $ok = ($new->getName() eq "aWeirdName123¿¿??ña");


$ok ? print "ok $test
" : print "not ok $test
";
$test++;

# end of t/01_ini.t

