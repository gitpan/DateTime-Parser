# ================================================================
package DateTime::Parser;
# ================================================================
use strict;
use warnings;
use utf8;

use vars qw(%EXPRESSIONS %SPECIFIER $VERSION);

$VERSION = 1.00;

use Carp;
use DateTime;
use DateTime::Locale;

%EXPRESSIONS = (
	ce_year		=> q[%Y],
	year		=> q[%Y],
	month		=> q[%m],
	mon 		=> q[%m],
	day			=> q[%d],
	day_of_month=> q[%d],
	mday		=> q[%d],
	day_of_week	=> q[%u], 
	wday		=> q[%u], 
	dow			=> q[%u], 
	day_of_year	=> q[%J], 
	doy			=> q[%J], 
	millisecond => q[%3N],
	microsecond => q[%6N],
	nanosecond  => q[%9N],
	hour		=> q[%H],
	minute		=> q[%M],
	min			=> q[%M],
	second		=> q[%S],
	sec			=> q[%S],
	'time'		=> q[%H:%M:%S],
	ymd			=> q[%Y-%m-%d],
	mdy			=> q[%m-%d-%Y],
	dmy			=> q[%d-%m-%Y],
	hms			=> q[%H:%M:%S],
	month_name	=> q[%B],
	month_abbr	=> q[%b],
	day_name	=> q[%A],
	day_abbr	=> q[%a],
	hour_12		=> q[%I],
	quarter		=> q[%x],
	quarter_abbr=> q[%q],
	quarter_name=> q[%Q],
	datetime	=> q[%Y-%m-%d T %H:%M:%S],
	iso8601 	=> q[%Y-%m-%d T %H:%M:%S],
	offset		=> q[%z],
	epoch 		=> q[%s],
	time_zone_long_name	=> q[%Z],
);

%SPECIFIER = (
	# abbreviated day name
	'a'			=> sub { my $locale = shift; return _get_list($locale->day_abbreviations()); },
	# full day name
	'A'			=> sub { my $locale = shift; return _get_list($locale->day_names()); },
	# abbreviated month name
	'b'			=> sub { my $locale = shift; return _get_list($locale->month_abbreviations()); },
	# full month name
	'B'			=> sub { my $locale = shift; return _get_list($locale->month_names()); },
	# two digit century
	'C'			=> sub { return '\d{2}' },
	# day of the month as a decimal number (range 01 to 31)
	'd'			=> sub { return '3[01]|[12]\d|0?[1-9]' },
	# %d, the day of the month as a decimal number, but a leading zero is replaced by a space
	'e'			=> sub { return '\s?[1-9]|[12]\d|3[01]' },
	# 4-digit year with century from weeknumber
	'G'			=> sub { return '\d{4}' },
	# 2-digit year with century from weeknumber
	'g'			=> sub { return '\d{2}' },
	# abbreviated month name
	'h'			=> sub { my $locale = shift; return _get_list($locale->month_abbreviations()); },
	# hour as a decimal number using a 24-hour clock (range 00 to 23)
	'H'			=> sub { return '0?\d|1\d|2[0-3]'; },
	# hour as a decimal number using a 12-hour clock (range 01 to 12)
	'I'			=> sub { return '0?[1-9]|1[012]'; },
	# day of the year as a decimal number (range 001 to 366).
	'j'			=> sub { return '0{0,2}[1-9]|0\d\d|3[0-6]\d'; },
	# OWN EXTENSION: day of the year as a decimal number
	'J'			=> sub { return '[1-9]|\d\d|3[0-6]\d'; },
	# hour as a decimal number (range 0 to 23); single digits are preceded by a blank.
	'k'			=> sub { return '\s?\d|1\d|2[0-3]'; },
	# hour as a decimal number (range 1 to 12); single digits are preceded by a blank.
	'l'			=> sub { return '\s?[1-9]|1[012]'; },
	# month as a decimal number (range 01 to 12)
	'm'			=> sub { return '0?[1-9]|1[012]'; },
	# minute as a decimal number (range 00 to 59)
	'M'			=> sub { return '[0-5]?\d'; },
	# newline
	'n'			=> sub { return '\n'; },
	# uppercase A.M., P.M.	
	'P'			=> sub { my $locale = shift; return uc(_get_list($locale->am_pms())); },
	# lowercase a.m., p.m.
	'p'			=> sub { my $locale = shift; return lc(_get_list($locale->am_pms()));},
	# OWN EXTENSION: quarter number
	'x'			=> sub { return '[1-4]'; },
	# OWN EXTENSION: quarter name
	'Q'			=> sub { my $locale = shift; return _get_list($locale->quarter_names()); },
	# OWN EXTENSION: abbreviated quarter name
	'q'			=> sub { my $locale = shift; return _get_list($locale->quarter_abbreviations()); },
	# seconds since the epoch
	's'			=> sub { return '\d{,11}'; },
	# seconds as decimal (range 00 to 61)
	'S'			=> sub { return '[0-5]\d|6[01]'; },
	# Tab
	't'			=> sub { return '\t'; },
	# day of the week as a decimal,(range 1 to 7)
	'u'			=> sub { return '[1-7]'; },
	# week number of the current year as a decimal number (range 00 to 53)
	'U'			=> sub { return '[0-4]?|5[0-3]'; },
	# week number of the current year as a decimal number (range 01 to 53)
	'V'			=> sub { return '0?[1-9]|[234]\d|5[0-3]'; },
	# day of the week as a decimal (range 0 to 6)
	'w'			=> sub { return '[0-6]'; },
	# week number of the current year as a decimal number (range 00 to 53)
	'W'			=> sub { return '[0-4]?\d|5[0-3]'; },
	# 2-digit year
	'y'			=> sub { return '\d{2}' },
	# 4-digit year
	'Y'			=> sub { return '[12]\d{3}'; },
	# timezone offset from UTC
	'z'			=> sub { return '[+-](?:1[0-4]|0\d)(?:00|15|30|45)';  },
	# timezone name
	'Z'			=> sub { 
		require DateTime::TimeZone;
		return join '|',map { "\Q$_\E" } @{DateTime::TimeZone->all_names};
	},
);

# -------------------------------------------------------------
sub new
# Description: Creates a DateTime::Parser object
# Type: Constructor
# Parameters: PATTERN,[LOCALE]
# Returnvalue: DateTime::Parser
# -------------------------------------------------------------
{
	my $class = shift;
	my $sPattern = shift;
	my $sLocale = shift;

	my $obj = bless {
		locale	=> undef,
		pattern	=> undef,
		regexp	=> undef,
		search	=> [],
	},$class;

	if (defined $sLocale) {
		$obj->set_locale($sLocale);
	} else {
		$obj->{'locale'} =  DateTime::Locale->load(DateTime->DefaultLocale());
	}
	
	$obj->set_pattern($sPattern);
	
	return $obj;
}

# -------------------------------------------------------------
sub set_locale
# Description: Sets the used locale
# Type: Public method
# Parameters: LOCALE
# Returnvalue: DateTime::Locale object
# -------------------------------------------------------------
{
	my $obj = shift;
	my $locale = shift;
	unless (ref($locale)) {
		$locale = DateTime::Locale->load($locale) 
			or croak('Invalid DateTime::Locale');
	} elsif (!$locale->isa('DateTime::Locale::Base')) {
		croak('Locale must be a DateTime::Locale object or locale string');
	}
	
	$obj->{'locale'} = $locale;
	if (defined $obj->{'regexp'}) {
		$obj->set_pattern($obj->{'pattern'});
	}
	return $locale;
}

# -------------------------------------------------------------
sub get_locale
# Description: Returns the currently used locale object
# Type: Public method
# Parameters: -
# Returnvalue: Locale
# -------------------------------------------------------------
{
	my $obj = shift;
	return $obj->{'locale'};
}

# -------------------------------------------------------------
sub set_pattern
# Description: Sets a pattern for the parser
# Type: Public method
# Parameters: STRFTIME FORMAT
# Returnvalue: 1
# -------------------------------------------------------------
{
	my $obj = shift;
	my $sFormat = shift || $obj->{'locale'}->default_date_format;
	
	$obj->{'pattern'} = $sFormat;
	$obj->{'regexp'} = '';
	$obj->{'search'} = [];
	
	# List of known specifiers
	my $sSpecifier = join '', keys %SPECIFIER;
	
	# Escape percent sign: very dirty hack
	$sFormat =~ s/\%\%/{\xb6}/g;
	
	# Expand methods
	$sFormat =~ s/%\{([a-z0-9_]+)\}/_get_expression($1)/ge;
	
	# Expand %D => %m/%d/%y
	$sFormat =~ s/\%D/%m\/%d\/%y/g;
	# Expand %F => %Y-%m-%d
	$sFormat =~ s/\%F/%Y-%m-%d/g;
	# Expand %r => %I:%M:%S %p
	$sFormat =~ s/\%r/%I:%M:%S %p/g;
	# Expand %P => %H:%M
	$sFormat =~ s/\%R/%H:%M/g;
	# Expand %T => %H:%M:%S
	$sFormat =~ s/\%T/%H:%M:%S/g;
	
	# Expand locale formats
	$sFormat =~ s/\%x/$obj->{'locale'}->default_date_format()/ge; #date
	$sFormat =~ s/\%X/$obj->{'locale'}->default_time_format()/ge; #time
	$sFormat =~ s/\%c/$obj->{'locale'}->default_datetime_format()/ge; #datetime
	
	$sFormat =~ s/([.\/\\()\[\]{}+?*])/\\$1/g;
	$sFormat =~ s/\s+/\\s+/g;
	
	$obj->{'regexp'} = '^';
	while ($sFormat ne '') {
		# Replace specifier
		if ($sFormat =~ s/^%([$sSpecifier])//s) {
			$obj->{'regexp'} .= '('.$SPECIFIER{$1}->($obj->{'locale'}).')';
			push @{$obj->{'search'}},$1;
		# Replace special \dN specifier
		} elsif ($sFormat =~ s/^%(\d?)N//s) {
			$obj->{'regexp'} .= '(\d{'.($1||9).'})';
			push @{$obj->{'search'}},'N'.$1;
		# Replace percent sign: very dirty hack
		} elsif ($sFormat =~ s/^\{\xb6\}//s) {
			$obj->{'regexp'} .= '\%';
		# Add other text to pattern
		} elsif ($sFormat =~ s/^\s+//s) {
			$obj->{'regexp'} .= '\\s+';
		} elsif ($sFormat =~ s/^([^%]+)//s) {
			$obj->{'regexp'} .= $1;
			next;
		} else {
			carp qq[DateTime::Locale could not parse the pattern: $sFormat];
		}
	}
	$obj->{'regexp'} .= '$';
	return 1;
}

# -------------------------------------------------------------
sub get_time
# Description: Creates a DateTime object from a string
# Type: Public method
# Parameters: DATETIME_STRING,[LOCALE]
# Returnvalue: DateTime object OR undef
# -------------------------------------------------------------
{
	my $obj = shift;
	my $sTime = shift;
	
	carp qq[No pattern set] unless (defined $obj->{'regexp'});
	
	# Execute pattern
	if ($sTime =~ m/$obj->{'regexp'}/is) {
		my (%hDatetime,%hCheck,%hTemp);
		no strict 'refs';
		for (my $i = 1; $i <= scalar(@{$obj->{'search'}}); $i++)  {
			$hTemp{$obj->{'search'}[$i-1]} = ${$i};
		}

		%hDatetime = (
			hour		=> 0,
			minute		=> 0,
			second		=> 0,
			time_zone	=> 'UTC',
		);
		
		foreach (keys %hTemp)  {
			my ($key,$value) = $obj->_get_result($_,$hTemp{$_});
			next unless (defined $key && defined $value);
			if ($key =~ /^_(.+)$/) {
				$hCheck{$1} = $value;
			} else {
				$hDatetime{$key} = $value;
			} 
		}
		
		if (defined $hCheck{'ampm'}
			&& $hDatetime{'hour'} > 0
			&& $hCheck{'ampm'} == 2) {
			$hDatetime{'hour'} += 12;
		}
		
		my $oDatetime = DateTime->new(%hDatetime);
		
		for (qw(wday quarter week doy)) {
			next unless (defined $hCheck{$_});
			carp(qq[DateTime object mismatch: $sTime says that $_ is $hCheck{$_} but in fact it is ].$oDatetime->$_)
				unless ($oDatetime->$_ == $hCheck{$_});
		}
		return $oDatetime;
	} 
	return undef;
}


# =============================================================
# Private methods

# -------------------------------------------------------------
sub _get_result
# Description: sets DateTime object values
# Type: Private private method
# Parameters: specifier, value, DateTime object
# Returnvalue: 1
# -------------------------------------------------------------
{
	my ($obj,$cSpecifier,$sValue);
	$obj = shift;
	$cSpecifier = shift;
	$sValue = shift;

	if ($cSpecifier eq 'b' || $cSpecifier eq 'h') {
		return 'month',_get_listpos($sValue,$obj->{'locale'}->month_abbreviations());
	} elsif ($cSpecifier eq 'B') {
		return 'month',_get_listpos($sValue,$obj->{'locale'}->month_names());
	} elsif ($cSpecifier eq 'a') {
		return '_wday',_get_listpos($sValue,$obj->{'locale'}->day_abbreviations());
	} elsif ($cSpecifier eq 'A') {
		return '_wday',_get_listpos($sValue,$obj->{'locale'}->day_names());
	} elsif ($cSpecifier eq 'C' || $cSpecifier eq 'y') {
		if ($sValue >= 70) {
			return 'year',(1900+$sValue);
		} else {
			return 'year',(2000+$sValue);
		}
	} elsif ($cSpecifier eq 'd' || $cSpecifier eq 'e') {
		return 'day',$sValue;
	} elsif ($cSpecifier eq 'H' || $cSpecifier eq 'k' || $cSpecifier eq 'I') {
		return 'hour',$sValue;
	} elsif ($cSpecifier eq 'm') {
		return 'month',$sValue;
	} elsif ($cSpecifier eq 'J') {	
		return '_doy',$sValue;
	} elsif ($cSpecifier eq 'N9') {
		return 'nanosecond',$sValue;
	} elsif ($cSpecifier eq 'N6') {
		$sValue *= 1000;
		return 'nanosecond',$sValue;
	} elsif ($cSpecifier eq 'N3') {
		$sValue *= 1000_000;
		return 'nanosecond',$sValue;
	} elsif ($cSpecifier eq 'M') {	
		return 'minute',$sValue;
	} elsif ($cSpecifier eq 'P' || $cSpecifier eq 'p') {
		return '_ampm',_get_listpos($sValue,$obj->{'locale'}->am_pms());
	} elsif ($cSpecifier eq 'x') {
		return '_quarter',$sValue;
	} elsif ($cSpecifier eq 'q') {
		return '_quarter',_get_listpos($sValue,$obj->{'locale'}->quarter_abbreviations());
	} elsif ($cSpecifier eq 'w') {
		return '_wday',$sValue;
	} elsif ($cSpecifier eq 'W') {
		return '_week_number',$sValue;
	} elsif ($cSpecifier eq 'Q') {
		return '_quarter',_get_listpos($sValue,$obj->{'locale'}->quarter_names ());
	} elsif ($cSpecifier eq 's') {
		return 'second',$sValue;
	} elsif ($cSpecifier eq 'Y') {
		return 'year',$sValue;
	} elsif ($cSpecifier eq 'Z' || $cSpecifier eq 'z') {
		return 'time_zone',$sValue;
	}
	return undef;
}


# -------------------------------------------------------------
sub _get_listpos
# Description: Helper method for creating regular expressions
# Type: Private class method
# Parameters: ARRAY_REF
# Returnvalue: partial regexp string
# -------------------------------------------------------------
{
	my $sValue = shift;
	my $aList = shift;
	for (my $i = 0; $i < scalar(@{$aList}); $i++) {
		if (lc($sValue) eq lc($aList->[$i])) {
			return $i+1;
		}
	}
	return undef;
}

# -------------------------------------------------------------
sub _get_list
# Description: Helper method for creating regular expressions
# Type: Private class method
# Parameters: ARRAY_REF
# Returnvalue: partial regexp string
# -------------------------------------------------------------
{
	my ($sResult,$aList);
	$aList = shift;
	$sResult .= join '|',@{$aList};
	return $sResult;
}

# -------------------------------------------------------------
sub _get_expression
# Description: translates a DateTime method into a strftime specifier
# Type: Private class method
# Parameters: EXPRESSION
# Returnvalue: strftime specifier
# -------------------------------------------------------------
{
	my ($sString);
	$sString = shift;
	return exists($EXPRESSIONS{$sString}) ? $EXPRESSIONS{$sString}:'';
}


__END__
=pod

=head1 NAME

DateTime::Parser - Locale aware Parser for DateTime

=head1 SYNOPSIS

    $obj = new DateTime::Parser();
    OR
    $obj = new DateTime::Parser('%d. %B %Y');
    OR
    $obj = new DateTime::Parser('%d. %B %Y','de-AT');
    
    my $date1 = $obj->get_time('5. Oktober 2007');

=head1 DESCRIPTON

This module provides a convenient function to parse localized date time
stings into DateTime objects. You just need to supply the used locale
and a strftime string describing the pattern.

=head1 USAGE

=head2 new([LOCALE])

    my $obj = DateTime::Parser->new();
    
    my $obj = DateTime::Parser->new('%d. %B %Y');
    
    my $obj = DateTime::Parser->new('%d. %B %Y','de-AT');
    
    my $locale = DateTime::Locale->get_locale('de-AT');
    my $obj = Config::Class->new('%d. %B %Y',$locale);

Creates a DateTime::Parser object and returns it. Takes the strftime format
string and the locale as an optional argument. If no locale is provided it will be
taken from C<DateTime->DefaultLocale()>. If the format string is omitted then the
C<medium_date_format> from the currently used locale will be used.

The locale may be a L<DateTime::Locale> object or a locale name as supplied to
C<DateTime::Locale->get_locale>

=head2 get_locale()

Returns the currently used DateTime::Locale object.

=head2 set_locale(LOCALE)

Sets the currently used locale. Accepts the name of the locale or a DateTime::Locale object.

=head2 set_pattern(PATTERN)

Sets the pattern. The format string can be any string containing DateTime
L<strftime Specifiers>

=head2 get_time(TIMESTRING)

    my $datetime = $obj->get_time('5. Oktober 2007')

Parses the given datetime strings and returns a datetime object. If the string cannot be
parsed the method returns undef.

=head2 strftime Specifiers

This module can parse all existing strftime specifiers and also a couple of method
specifiers (C<%{method_name}>), but it can only use some of them to construct
a DateTime object, since not all specifiers are easily (or event at all) reversible.

=head3 Supported DateTime Methods

=over 2

* item ce_year
* item year
* item month, mon
* item day,mday
* item hour
* item minute
* item second
* item time
* item ymd
* item mdy
* item dmy
* item month_name
* item month_abbr
* item day_name
* item day_abbr
* item hour_12
* item quarter
* item quarter_name
* item quarter_abbr
* item millisecond
* item microsecond
* item nanosecond
* item datetime
* item iso8601
* item hms
* item offset
* item epoch
* item time_zone_long_name

=back

=head3 Unsupported DateTime Methods

=over 2

* item era_abbr
* item christian_era
* item secular_era
* item day_of_quarter
* item doq
* item year_with_era
* item year_with_christian_era
* item year_with_secular_era
* item hour_1
* item hour_12_0
* item fractional_second
* item week
* item week_year
* item week_number
* item jd
* item mjd
* item hires_epoch

=back

=head3 Reversible Strftime Specifiers

Only the specifiers clearly indicating a single time zone, year, month, day, hour,
minute, second or nanosecond can be used to construct a DateTime object. Time using
the 1-12 hour range is fine as long the %P (or %p) sepecifier is used.

=head3 Sanity Checks

Although the module cannot construct a date from a weekday, quarter or week number
it used this data to perform sanity checks. The module will throw an exception if
a 'Tuesday, October 1, 2007' will be parsed since this day was a Monday.

Sanity checks are performed on all specifiers clearly indicating a week number, quarter,
weekday or day of year. They are not performed on week of month, week year, day of quarter
values.

=head1 KNOWN BUGS & LIMITATIONS

This module can only work with dates from the current and last millennium. This could be changed
if deemed necessary.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

DateTime::Parser is Copyright (c) 2006,2007 Maroš Kollár.
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

The L<DateTime> module by Dave Rolsky.

=cut
