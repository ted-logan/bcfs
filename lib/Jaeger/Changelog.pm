package		Jaeger::Changelog;

#
# $Id: Changelog.pm,v 1.1 2002-05-19 22:55:47 jaeger Exp $
#

# changelog package for jaegerfesting

# 28 May 2000
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

@Jaeger::Changelog::ISA = qw(Jaeger::Base);

@Jaeger::Changelog::Params = qw(id title time_begin time_end content);

# returns a new object
# call optionally with id
sub new {
	my $package = shift;

	my $self = $package->SUPER::new();
  
	my $id = shift;
	if(defined $id) {
		$self->_db_select("where id = $id")
			or return;
	} else {
		$self->_set();
	}

	return $self;
}

# returns the newest changelog
sub newest {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->_db_select("order by time_begin desc limit 1")
		or return;

	return $self;
}

# internal function; selects a row from the database
sub _db_select {
	my $self = shift;
	my $specify = shift;

	my $sql = "select * from changelog $specify";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	if(my @row = $sth->fetchrow_array()) {
		$self->_set(@row);
		return 1;
	} else {
		return;
	}
}

sub _set {
	my $self = shift;

	foreach my $value (@Jaeger::Changelog::Params) {
		$self->{$value} = shift;
	}
}

sub insert {
	my $self = shift;

	my %insert = (
		title => $self->{title},
		content => $self->{content}
	);

	if($self->{time_begin}) {
		$insert{time_begin} = $self->{time_begin};
		if($self->{time_end}) {
			$insert{time_end} = $self->{time_end};
		} else {
			$insert{time_end} = $self->{time_begin};
		}
	}

	my $sql = 'insert into changelog (' . join(', ', keys %insert) .
		') values (' .
		join(', ', map {$self->{dbh}->quote($insert{$_})} keys %insert).
		')';

	$self->{dbh}->do($sql) or warn "$sql;\n";
	return $sql;
}

# returns an object for the previous changelog, if any
sub _prev {
	my $self = shift;

	my $sql = "select * from changelog where time_begin = (select max(time_begin) from changelog where time_begin < '" . $self->{time_begin} . "')";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql\n";

	if(my @row = $sth->fetchrow_array()) {
		$self->{prev} = new ref $self;
		$self->{prev}->_set(@row);
	} else {
		$self->{prev} = undef;
	}
	return $self->{prev};
}

# returns an object for the next changelog, if any
sub _next {
	my $self = shift;

	my $sql = "select * from changelog where time_begin = (select min(time_begin) from changelog where time_begin > '" . $self->{time_begin} . "')";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute() or warn "$sql\n";

	if(my @row = $sth->fetchrow_array()) {
		$self->{next} = new ref $self;
		$self->{next}->_set(@row);
	} else {
		$self->{next} = undef;
	}
	return $self->{next};
}

# returns a link to the url of this changelog
sub _url {
	my $self = shift;
	return $self->{url} = "$Jaeger::Base::BaseURL/changelog.cgi?id=$self->{id}";
}

# returns html for this object
sub _html {
	my $self = shift;

	return $self->lf()->changelog(%$self);

}

# returns an array with all of the changelog in the database
# optional paramaters: whereclause orderclause limit nocontent
# call as class method
sub All {
	my $package = shift;
	my ($where, $order, $limit, $nocontent) = @_;
	my @retval;

	my $sql = "select * from changelog";
	$sql .= " where $where" if $where;
	$sql .= " order by $order" if $order;
	$sql .= " limit $limit" if $limit;
	my $sth = $Jaeger::Base::Pgdbh->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	while(my @row = $sth->fetchrow_array()) {
		my $changelog = $package->new();
		$changelog->_set(@row);
		$changelog->{content} = undef if $nocontent;
		push @retval, $changelog;
	}

	return @retval;
}

# returns the total number of changelog in the database
# optional paramater: whereclause
# call as a class method
sub Count {
	my $package = shift;
	my $where = shift;

	my $sql = "select count(*) from changelog";
	$sql .= " where $where" if $where;
	my $sth = $Jaeger::Base::Pgdbh->prepare($sql);
	$sth->execute() or warn "$sql;\n";
	return ($sth->fetchrow_array())[0];
}
