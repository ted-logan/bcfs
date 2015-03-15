package	Jaeger::Photo::List::Round;

# 
# $Id: Round.pm,v 1.1 2003-01-10 06:58:12 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Displays a list of photos and thumbnails according to a round

# created  08 January 2003

use strict;

use Carp;
use Time::Local;

@Jaeger::Photo::List::Round::ISA = qw(Jaeger::Photo::List);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{round} = shift;

	return $self;
}

sub _statusquery {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{statusquery} = "status <= $status and not hidden";
}


# returns a list reference containing the photos for this date
sub _photos {
	my $self = shift;

	my $statusquery = $self->statusquery();
	return $self->{photos} = [Jaeger::Photo->Select(
		"round = '$self->{round}' and $statusquery order by round, number"
	)];
}

#
# methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = "Photo round $self->{round}";
}

sub _prev {
	my $self = shift;

	my $sql = "select max(round) from photo where round < '$self->{round}'";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	my ($prev) = $sth->fetchrow_array();
	if($prev) {
		$self->{prev} = new Jaeger::Photo::List::Round($prev);
	} else {
		$self->{prev} = undef;
	}

	return $self->{prev};
}

sub _next {
	my $self = shift;

	my $sql = "select min(round) from photo where round > '$self->{round}'";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	my ($next) = $sth->fetchrow_array();
	if($next) {
		$self->{next} = new Jaeger::Photo::List::Round($next);
	} else {
		$self->{next} = undef;
	}

	return $self->{next};
}

sub _url {
	my $self = shift;

	return $self->{url} = "photo.cgi?round=$self->{round}";
}
