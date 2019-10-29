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

use Jaeger::Photo::List::Date;
use Jaeger::Thumbnail qw(year_thumbnail);
use Jaeger::User;

use Carp;
use POSIX qw(strftime);
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

sub years {
	my $self = shift;

	my @years;

	my $sql = "select year from photo_year";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";
	while(my ($year) = $sth->fetchrow_array()) {
		push @years, $year;
	}

	return sort @years;
}

sub _statusquery {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{statusquery} = "status <= $status";
}

#
# methods used by Jaeger::Lookfeel to show this page
#

# returns the html for this object
sub html {
	my $self = shift;

	my $where = "date_part('year', date) = $self->{year} and " .
		$self->statusquery();

	my %dates;
	foreach my $date (Jaeger::Photo::List::Date->Select($where)) {
		$dates{$date->date()} = $date->url();
	}

	return $self->lf()->photo_year_list(
		thumbnail => year_thumbnail($self->{year}, \%dates),
		years => $self->yearlist()
	);
}

sub yearlist {
	my $self = shift;

	return 
		qq'<div class="articlefooter"><hr noshade><center><small>' .
		join(' | ', map { qq'<a href="/photo/$_/">$_</a>' } $self->years()).
		' | <a href="/photo/">Recent photos</a>' .
		"</small></center><hr noshade></div>\n";
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

	return $self->{url} = "/photo/$self->{year}/";
}

sub _xrefs {
	my $self = shift;

	return $self->{xrefs} = [];
}

# Return a mini navigation bar, to be shown on the right side of the screen
sub mininav {
	my $self = shift;

	return join(' • ', map { qq'<a href="/photo/$_/">$_</a>' } $self->years()) .
		' • <a href="/photo/">Recent photos</a>';
}
