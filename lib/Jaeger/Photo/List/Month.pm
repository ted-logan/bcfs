package	Jaeger::Photo::List::Month;

# Displays a list of photos and thumbnails from a month

use strict;

use Carp;
use Time::Local;

use Jaeger::Photo::Notfound;
use Jaeger::Photo;
use Jaeger::User;

@Jaeger::Photo::List::Month::ISA = qw(Jaeger::Photo::List);

sub table {
	return 'photo_month';
}

sub new {
	my $package = shift;
	my $self;

	if(ref $_[0] eq 'HASH') {
		$self = $package->SUPER::new(@_);
	} else {
		$self = $package->SUPER::new();

		my $date = shift;

		if($date =~ /^(\d\d\d\d-\d\d?)-\d\d?$/) {
			# ISO-format date. Drop the day, replace it with the
			# first of the month.
			$self->{month} = "$1-01";

		} elsif($date =~ /^\d\d\d\d-\d\d?$/) {
			# ISO-format month.
			$self->{month} = "$date-01";

		} else {
			# invalid date
			carp "Jaeger::Photo::List::Month->new(): Invalid month $date";
		}
		warn "Creating month $self->{month}";

		my $photos = $self->photos();
		unless(@$photos) {
			# No visible photos for this date.
			return new Jaeger::Photo::Notfound;
		}
	}

	return $self;
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

	my $sql = "select id from photo_date " .
		"where date_trunc('month', date) = " .
		$self->dbh()->quote($self->month()) .
		" and " . $self->statusquery();

	return $self->{photos} =
		[Jaeger::Photo->Select("id in ($sql) order by rowkey")];
}

#
# methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	my $month = $self->{month};
	$month =~ s/-01$//;

	return $self->{title} = "Photos in $month";
}

sub _prev {
	my $self = shift;

	my $where = "month < " . $self->dbh()->quote($self->{month}) . " and " .
		$self->statusquery() .
		" order by month desc";
	return $self->{prev} =
		scalar Jaeger::Photo::List::Month->Select($where);
}

sub _next {
	my $self = shift;

	my $where = "month > " . $self->dbh()->quote($self->{month}) . " and " .
		$self->statusquery() .
		" order by month asc";
	return $self->{prev} =
		scalar Jaeger::Photo::List::Month->Select($where);
}

sub _index {
	my $self = shift;

	my $year = (split /-/, $self->{month})[0];

	return $self->{index} = Jaeger::Photo::Year->new($year);
}

sub _url {
	my $self = shift;

	my $month = $self->{month};
	$month =~ s/-01$//;
	$month =~ s/-/\//g;

	return $self->{url} = $Jaeger::Base::BaseURL . "photo/$month/";
}
