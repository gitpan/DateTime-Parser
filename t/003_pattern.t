# -*- perl -*-

# t/003_pattern.t - check parsing

use Test::More tests => 49;

use DateTime::Parser;

my $date;
my $object = DateTime::Parser->new();
$object->set_locale('de');


ok ($object->set_pattern('pattern'));
is ($object->{'pattern'},'pattern','1. Pattern set');
is ($object->{'regexp'},'^pattern$','2. Regexp created');
is (ref($object->{'search'}),'ARRAY','3. Search capture created');
ok ($object->set_pattern('%Y-%m-%d'),'Set pattern %Y-%m-%d');

check_pattern('%Y-%m-%d','2007-10-30',day => 30, month => 10, year => 2007);
check_pattern('%Y-%m-%d','2006-11-30',day => 30, month => 11, year => 2006);
check_pattern('%d.%m.%Y','27.03.1979',day => 27, month => 3, year => 1979);
check_pattern('%A, %d.%B,%Y','Montag, 1.Oktober,2007',day => 1, month => 10, year => 2007);
check_pattern('%A, %d.%B,%Y %H:%M','Montag, 1.Oktober,2007 20:30',day => 1, month => 10, year => 2007, hour => 20, minute => 30);
check_pattern('%F','2001-10-30',day => 30, month => 10, year => 2001);
check_pattern('%{dmy}','12-01-2001',day => 12, month => 1, year => 2001);
check_pattern('[%{day_of_week}] %{dmy}','[1] 12-01-2001',day => 12, month => 1, year => 2001);
check_pattern('%a, %d %b %Y %H:%M:%S %z','Fr, 01 Okt 1999 9:15:00 +0630',day => 1, month => 10, year => 1999, hour => 9, minute => 15, offset => '23400');
check_pattern('%A, %d %B %Y %H:%M:%S %Z','Sonntag, 01 Oktober 1989 9:15:00 Europe/Vienna',day => 1, month => 10, year => 1989, hour => 9, minute => 15, offset => '3600');
check_pattern('%d.%m.%Y %r','12.01.2001 11:30:00 nachm.',day => 12, month => 1, year => 2001, hour => 23,minute => 30);


sub check_pattern {
	my $pattern = shift;
	my $string = shift;
	my $date = { @_ };
	my $gotdate;
	
	ok ($object->set_pattern($pattern),"Set pattern $pattern");
	ok ($gotdate = $object->get_time($string),"Get time $string with pattern $pattern :$object->{'regexp'})");
	isa_ok($gotdate,'DateTime');
	foreach (keys %$date) {
		no strict 'refs';
		unless ($gotdate->$_ eq $date->{$_}) {
			fail ("Compare time $string: $_ does not match: (expected $date->{$_}, got ".$gotdate->$_.")");
			last;
		}
	}
	pass("Compare time $gotdate <-> $string");
	return;
}