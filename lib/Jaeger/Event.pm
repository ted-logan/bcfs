package Jaeger::Event;

#
# $Id: Event.pm,v 1.1 2005-04-02 06:22:30 jaeger Exp $
#

# Jaeger::Event: Allows tracking of upcoming events
# 01 April 2005

use strict;

use Jaeger::Base;

@Jaeger::Event::ISA = qw(Jaeger::Base);

use Carp;

sub table {
	return 'event';
}

# Validate data for submission
sub update {
	my $self = shift;

	unless($self->{user_id}) {
		if($self->{user}) {
			$self->{user_id} = $self->{user};
		} else {
			carp "Jaeger::Event->update(): user must be set";
			return undef;
		}
	}

	unless($self->{name}) {
		carp "Jaeger::Event->update(): name must be set";
		return undef;
	}

	unless($self->{date}) {
		carp "Jaeger::Event->update(): date must be set";
		return undef;
	}

	if(!$self->{recurring} || $self->{recurring} =~ /^f/i) {
		$self->{recurring} = 'false';
	} else {
		$self->{recurring} = 'true';
	}

	$self->SUPER::update();
}

# Finds the user's events that will occur in the next n days
sub Upcoming {
	my $package = shift;

	my $user = shift;
	unless(ref $user) {
		carp "Jaeger::Event->Upcoming(): user must be specified";
		return undef;
	}

	my $n = shift;
	unless($n) {
		$n = 31;
	}

	# These events are easy: non-recurring events
	my @events = Jaeger::Event->Select("user_id = " . $user->id() . " and recurring is false and date >= now() and date <= now() + '$n days'");

	# Recurring events are harder; fortunately, the hard work has
	# been done for us in the SQL view.
	my @recurring = Jaeger::Event::Recurring->Select("user_id = " . $user->id() . " and date >= now() and date <= now() + '$n days'");
#	my @recurring = ();

	return sort {$a->{date} <=> $b->{date}} (@events, @recurring);
}

package Jaeger::Event::Recurring;

@Jaeger::Event::Recurring::ISA = qw(Jaeger::Event);

sub table {
	return 'recurring_event';
}
