package	Jaeger::Photo::List::Date;

# 
# $Id: Date.pm,v 1.1 2003-01-10 06:58:03 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Displays a list of photos and thumbnails according to a date

# created  08 January 2003

use strict;

use Carp;
use Time::Local;

@Jaeger::Photo::List::Date::ISA = qw(Jaeger::Photo::List);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	my $date = shift;

	if($date =~ /^\d\d\d\d-\d\d?-\d\d?$/) {
		# ISO-format date
		$self->{date} = $date;

	} elsif($date =~ /^\d+$/) {
		# time_t
		$self->{unixdate} = $date;


		# convert time_t into ISO date
		my @date = (gmtime($date))[5, 4, 3];
		$date[0] += 1900;
		$date[1]++;
		$self->{date} = sprintf '%04s-%02s-%02s', @date;

	} else {
		# invalid date
		carp "Jaeger::Photo::List::Date->new(): Invalid date $date";
	}

	return $self;
}

# parse the ISO-format date ('2003-01-08') into a time_t
sub _unixdate {
	my $self = shift;

	my @date = split /-/, $self->{date};
	$date[0] -= 1900;
	$date[1]--;
	return $self->{unixdate} = timegm(0, 0, 0, reverse @date);
}

# returns a list reference containing the photos for this date
sub _photos {
	my $self = shift;

	my @photos;

	my $sql = "select id from photo_date where date = " .
		$self->unixdate();

	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	while(my ($id) = $sth->fetchrow_array()) {
		push @photos, Jaeger::Photo->new_id($id);
	}

	$self->{photos} = [sort {$a->{round} cmp $b->{round} || $a->{number} cmp $b->{number}} @photos];

	return $self->{photos};
}

#
# methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = "Photos on $self->{date}";
}

sub _prev {
	my $self = shift;

	my $sql = "select max(date) from photo_date where date < " .
		$self->unixdate();
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	my ($prev) = $sth->fetchrow_array();
	if($prev) {
		$self->{prev} = new Jaeger::Photo::List::Date($prev);
	} else {
		$self->{prev} = undef;
	}

	return $self->{prev};
}

sub _next {
	my $self = shift;

	my $sql = "select min(date) from photo_date where date > " .
		$self->unixdate();
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	my ($next) = $sth->fetchrow_array();
	if($next) {
		$self->{next} = new Jaeger::Photo::List::Date($next);
	} else {
		$self->{next} = undef;
	}

	return $self->{next};
}

sub _index {
	my $self = shift;

	my $year = (split /-/, $self->{date})[0];

	return $self->{index} = Jaeger::Photo::Year->new($year);
}

sub _url {
	my $self = shift;

	return $self->{url} = "photo.cgi?date=$self->{date}";
}
