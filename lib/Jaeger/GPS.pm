package Jaeger::GPS;

#
# $Id: GPS.pm,v 1.2 2007-03-01 02:58:00 jaeger Exp $
#

# Jaeger::GPS: GPS tracking wrapper
# 22 February 2007

use strict;

use Jaeger::Base;

@Jaeger::GPS::ISA = qw(Jaeger::Base);

use Carp;
use Math::Trig qw(great_circle_distance deg2rad);

use overload
	'==' => \&equality,
	'-' => \&distance,
	'""' => \&toString;

sub table {
	return 'gps_track';
}

# Validate data for submission
sub update {
	my $self = shift;

	unless($self->{date}) {
		carp "Jaeger::GPS->update(): date is unset";
		return undef;
	}

	unless($self->{latitude}) {
		carp "Jaeger::GPS->update(): latitude is unset";
		return undef;
	}

	unless($self->{longitude}) {
		carp "Jaeger::GPS->update(): longitude is unset";
		return undef;
	}

	$self->SUPER::update();
}

sub equality {
	return ($_[0]->latitude() == $_[1]->latitude()) &&
		($_[0]->longitude() == $_[1]->longitude());
}

# Compute the great circle distance between this point
# and the adjacent point, in kilometers
sub distance {
	my @a = (deg2rad($_[0]->longitude()), deg2rad(90 - $_[0]->latitude()));
	my @b = (deg2rad($_[1]->longitude()), deg2rad(90 - $_[1]->latitude()));

	my $km = great_circle_distance(@a, @b, 6378);
}

sub toString {
	my $self = shift;

	return sprintf "[%s] %.5f, %.5f",
		scalar(localtime $self->date()),
		$self->longitude(),
		$self->latitude();
}

1;
