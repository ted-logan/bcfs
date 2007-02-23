package Jaeger::GPS;

#
# $Id: GPS.pm,v 1.1 2007-02-23 03:25:38 jaeger Exp $
#

# Jaeger::GPS: GPS tracking wrapper
# 22 February 2007

use strict;

use Jaeger::Base;

@Jaeger::GPS::ISA = qw(Jaeger::Base);

use Carp;

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

1;
