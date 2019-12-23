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

use Jaeger::Photo::Notfound;
use Jaeger::Photo;
use Jaeger::Photo::List::Month;
use Jaeger::User;

@Jaeger::Photo::List::Date::ISA = qw(Jaeger::Photo::List);

sub table {
	return 'photo_date_view';
}

sub new {
	my $package = shift;
	my $self;

	if(ref $_[0] eq 'HASH') {
		$self = $package->SUPER::new(@_);
	} else {
		$self = $package->SUPER::new();

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

		my $photos = $self->photos();
		unless(@$photos) {
			# No visible photos for this date.
			return new Jaeger::Photo::Notfound;
		}
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

sub _statusquery {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{statusquery} = "status <= $status";
}

# returns a list reference containing the photos for this date
sub _photos {
	my $self = shift;

	my $sql = "select id from photo_date where date_trunc('day', date) = " .
		$self->dbh()->quote($self->date()) .
		" and " . $self->statusquery();

	return $self->{photos} =
		[Jaeger::Photo->Select("id in ($sql) order by rowkey")];
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

	my $sql = "select max(unixdate) from photo_date where unixdate < " .
		$self->unixdate() .
		" and " . $self->statusquery();
	my $sth = $self->dbh()->prepare($sql);
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

	my $sql = "select min(unixdate) from photo_date where unixdate > " .
		$self->unixdate() .
		" and " . $self->statusquery();
	my $sth = $self->dbh()->prepare($sql);
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

	return $self->{index} = Jaeger::Photo::List::Month->new($self->{date});
}

sub _url {
	my $self = shift;

	my $date = $self->{date};
	$date =~ s/-/\//g;

	return $self->{url} = $Jaeger::Base::BaseURL . "photo/$date/";
}
