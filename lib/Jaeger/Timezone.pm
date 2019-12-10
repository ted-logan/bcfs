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

use POSIX;

use Jaeger::Base;

@Jaeger::Timezone::ISA = qw(Jaeger::Base);

sub table {
	return 'timezone';
}

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
		# eg "Tuesday 15 October 2019"
		return POSIX::strftime("%A %d %B %Y", @date);
	}

	# eg "19:45:44 PST Monday 09 December 2019"
	return POSIX::strftime("%T $self->{name} %A %d %B %Y", @date);
}
