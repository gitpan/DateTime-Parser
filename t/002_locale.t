# -*- perl -*-

# t/002_set.t - check object creation


use Test::More tests => 7;

use DateTime::Parser;


my $object = DateTime::Parser->new();

isa_ok ($object->{'locale'}, 'DateTime::Locale::Base');

$defaultlocale = DateTime::Locale->load(DateTime->DefaultLocale());
is ($object->{'locale'}, $defaultlocale,"Default locale");

is ($defaultlocale, $object->get_locale,"Locale accessor");

$newlocale = DateTime::Locale->load('de');

ok ($object->set_locale('de'),"Set locale with name");
is ($object->{'locale'},$newlocale,"Set locale with name ist successful");

ok ($object->set_locale($newlocale),"Set locale with object");
is ($object->{'locale'},$newlocale,"Set locale with object is successful");
