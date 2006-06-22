package		Jaeger::Flight;

#
# $Id: Flight.pm,v 1.1 2006-06-22 03:00:44 jaeger Exp $
#

# A list of all flights I've taken
# (Which hopefully won't become a macabre spectacle.)

# 15 June 2006
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

@Jaeger::Flight::ISA = qw(Jaeger::Base);

sub table {
	return 'flights';
}

sub _year {
	my $self = shift;

	my $year = $self->{month};

	$year =~ s/-.*//;

	return $self->{year} = $year;
}

sub _html {
	my $self = shift;

	return $self->{_html} = $self->lf()->flight_row(
		%$self
	);
}

package Jaeger::Flight::List;

@Jaeger::Flight::List::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	return bless {}, $package;
}

sub title {
	return "All Flights";
}

sub html {
	my $self = shift;

	my @flights = Jaeger::Flight->Select();

	# Compute totals
	my %total;
	foreach my $flight (@flights) {
		$total{$flight->year()}->{miles} += $flight->distance();
		$total{$flight->year()}->{flights}++;
		$total{9999}->{miles} += $flight->distance();
		$total{9999}->{flights}++;
	}

	# Append the totals and resort the array
	foreach my $year (keys %total) {
		push @flights, Jaeger::Flight::Total->new($year,
			$total{$year}->{miles}, $total{$year}->{flights});
	}
	@flights = sort {$a->month() cmp $b->month()} @flights;

	# Display the flight table
	my @rows = map {$_->html()} @flights;

	return $self->lf()->flight_table(
		data => join('', @rows)
	);
}

package Jaeger::Flight::Total;

@Jaeger::Flight::Total::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	my $year = shift;
	my $miles = shift;
	my $flights = shift;

	my $self = {
		month => "$year-13-01",
		distance => $miles,
		flights => $flights
	};

	if($year == '9999') {
		$self->{year} = "Grand";
	} else {
		$self->{year} = $year;
	}

	return bless $self, $package;
}

sub _html {
	my $self = shift;

	return $self->{_html} = $self->lf()->flight_total(
		%$self
	);
}

1;
