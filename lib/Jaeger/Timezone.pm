package	Jaeger::Timezone;

# 
# $Id: Timezone.pm,v 1.2 2003-07-05 02:14:01 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Provides a handy-dandy interface to timezones, which I've recently
# decided is especially useful metadata

# created  05 January 2003

use strict;

use Jaeger::Base;

@Jaeger::Timezone::ISA = qw(Jaeger::Base);

sub table {
	return 'timezone';
}

@Jaeger::Timezone::Months = qw(January February March April May June July August September October November December);
@Jaeger::Timezone::Weekdays = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

# formats the given date (epoch seconds) according to the time zone
sub format {
	my $self = shift;

	my $time = shift;

	if($time == 0) {
		return undef;
	}

	# the GMT offset (ofst) is in hours
	$time += $self->{ofst} * 3600;

	my @date = gmtime($time);

	# if the time is precisely midnight, don't display it
	if(($time % 86400) == 0) {
		return sprintf "%s %02d %s %04d %s",
			$Jaeger::Timezone::Weekdays[$date[6]],  # weekday
			$date[3],                               # day of month
			$Jaeger::Timezone::Months[$date[4]],    # month
			$date[5] + 1900,                        # year
			$self->{name};                          # time zone
	}

	# Perhaps I should just use strftime() instead of this mess.

	return sprintf "%02d:%02d:%02d %s %s %02d %s %04d",
		$date[2], $date[1], $date[0],		# time
		$self->{name},				# time zone
		$Jaeger::Timezone::Weekdays[$date[6]],	# weekday
		$date[3],				# day of month
		$Jaeger::Timezone::Months[$date[4]],	# month
		$date[5] + 1900;			# year
}
