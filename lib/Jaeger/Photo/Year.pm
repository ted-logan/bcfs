package	Jaeger::Photo::Year;

# 
# $Id: Year.pm,v 1.1 2003-01-10 06:57:42 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Displays a year's worth of month thumbnails representing the year

# created  08 January 2003

use strict;

use Jaeger::Base;

@Jaeger::Photo::Year::ISA = qw(Jaeger::Base);

use Jaeger::Thumbnail qw(year_thumbnail);

use Carp;
use Time::Local;

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{year} = shift;
	unless($self->{year}) {
		$self->{year} = (localtime)[5] + 1900;
	}

	return $self;
}

#
# methods used by Jaeger::Lookfeel to show this page
#

# returns the html for this object
sub html {
	my $self = shift;

	my %dates;

	my $year_begin = timegm(0, 0, 0, 1, 0, $self->{year});
	my $year_end = timegm(0, 0, 0, 1, 0, $self->{year} + 1);

	my $sql = "select date, count(*) from photo_date where date >= $year_begin and date < $year_end group by date";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";
	while(my ($date, $count) = $sth->fetchrow_array()) {
		my $date_iso = do {
			my @date = (gmtime($date))[5, 4, 3];
			$date[0] += 1900;
			$date[1]++;
			sprintf("%04d-%02d-%02d", @date);
		};
		$dates{$date_iso} = "photo.cgi?date=$date_iso";
	}

	return "<tr><td>" . year_thumbnail($self->{year}, \%dates) . "</td></tr>";
}

sub _title {
	my $self = shift;

	return $self->{title} = "Photos in $self->{year}";
}

sub _prev {
	my $self = shift;

	# assume that no photos exist prior to 1998
	if($self->{year} == 1998) {
		# FIXME link to undated photos
	} else {
		$self->{prev} = new Jaeger::Photo::Year($self->{year} - 1);
	}

	return $self->{prev};
}

sub _next {
	my $self = shift;

	# assume that no photos exist past the current year
	if($self->{year} < ((localtime)[5] + 1900)) {
		$self->{next} = new Jaeger::Photo::Year($self->{year} + 1);
	}

	return $self->{next};
}

sub _url {
	my $self = shift;

	return $self->{url} = "photo.cgi?year=$self->{year}";
}
