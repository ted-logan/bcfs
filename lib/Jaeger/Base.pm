package Jaeger::Base;

#
# $Id: Base.pm,v 1.7 2003-11-05 04:22:07 jaeger Exp $
#
# Copyright (c) 1999, 2000 x13.com
# Copyright (c) 2001, 2002 Buildmeasite.com

# base for all jaegerfesting modules: shares a database connection
# and allow accessing internal stuff via AUTOLOAD

# created  18 August 1999 for x13.com
# modified 26 June 2001 for Buildmeasite.com
# updated  28 August 2002 for bmas 2.0
# updated  28 October 2002 for jaegerfesting 2.0

use strict;
use DBI;
use Carp;

use Jaeger::Lookfeel;
use CGI;

$Jaeger::Base::Pgdbh = DBI->connect("DBI:Pg:dbname=jaeger", "", "");

unless($Jaeger::Base::Pgdbh) {
	die "Jaeger::Base: Unable to connect to pg database\n";
}

$Jaeger::Base::BaseURL = 'http://jaeger.festing.org/';

#
# global data to keep track of child modules
#

# hash of packages; inside is a hash reference containing the ids
# => instantiated objects
$Jaeger::Base::Ids = ();

#
# Data used by various child modules
#
@Jaeger::Base::Months = qw(blah January February March April May June July August September October November December);
@Jaeger::Base::Weekdays = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);


# the shared CGI query object between all objects
$Jaeger::Base::Query = undef;

sub Query {
	unless($Jaeger::Base::Query) {
		$Jaeger::Base::Query = new CGI;
	}
	return $Jaeger::Base::Query;
}

# the shared look-and-feel object between all objects
$Jaeger::Base::Lookfeel = undef;

sub Lookfeel {
	unless($Jaeger::Base::Lookfeel) {
		$Jaeger::Base::Lookfeel = new Jaeger::Lookfeel;
	}
	return $Jaeger::Base::Lookfeel;
}

# creates an object, either empty or with the specified data
sub new {
	my $package = shift;
	my $self = ref $_[0] eq 'HASH' ? {%{$_[0]}} : {};

	$self->{dbh} = $Jaeger::Base::Pgdbh;
	$self->{table} = $package->table();

	if($self->{id}) {
		if($Jaeger::Base::Ids{$package}->{$self->{id}}) {
			return $Jaeger::Base::Ids{$package}->{$self->{id}};
		} else {
			$Jaeger::Base::Ids{$package}->{$self->{id}} = $self;
		}
	}

	bless $self, $package;

	if(scalar keys %$self == 2) {
		foreach my $column ($self->columns()) {
			$self->{$column} = undef;
		}
	}

	return $self;
}

# returns a new object according to its id, looking up in the cache
# to see if one already exists
sub new_id {
	my $package = shift;

	my $id = shift;

	my $list = $Jaeger::Base::Ids{$package};

	unless(exists $list->{$id}) {
		$list->{$id} = $package->Select(id => $id);
	}
	return $list->{$id};
}

# selects one or more objects from the relevant database
sub Select {
	my $package = shift;
	if(ref $package) {
		$package = ref $package;
	}

	my $dbh = $Jaeger::Base::Pgdbh;

	my $whereclause;
	if(@_ == 1) {
		$whereclause = ' where ' . shift;
	} elsif(@_) {
		my %data = @_;
		$whereclause = ' where ' . join(' and ',
			map {"$_ = " . $dbh->quote($data{$_})}
				keys %data
			);
	}

	unless($package->table()) {
		die "$package doesn't have a table\n";
	}

	my $sql = "select * from " . $package->table() . $whereclause;

	my $sth = $dbh->prepare($sql);
	$sth->execute()
		or warn "$sql;\n";

	# do we want just one, or multiple results?
	if(wantarray) {
		my @results;

		while(my $result = $sth->fetchrow_hashref()) {
			push @results, $package->new($result);
		}

		return @results;

	} else {
		if(my $result = $sth->fetchrow_hashref()) {
			return $package->new($result);
		} else {
			return undef;
		}
	}
}

# returns the number of database rows corresponding to the selection query
sub Count {
	my $package = shift;

	my $dbh = $Jaeger::Base::Pgdbh;

	my $whereclause;
	if(@_ == 1) {
		$whereclause = ' where ' . shift;
	} elsif(@_) {
		my %data = @_;
		$whereclause = ' where ' . join(' and ',
			map {"$_ = " . $dbh->quote($data{$_})}
				keys %data
			);
	}

	my $sql = "select count(*) from " . $package->table() . $whereclause;

	my $sth = $dbh->prepare($sql);
	$sth->execute()
		or warn "$sql;\n";

	return ($sth->fetchrow_array())[0];
}

# in case the child doesn't actually have a table associated with it
sub table {
	return undef;
}

# returns an array containing the columns in a table
sub columns {
	my $self = shift;

	my $sql = "select attname from pg_attribute where attrelid = " .
		"(select oid from pg_class where relname = '" . $self->table() .
		"') and attnum > 0";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute()
		or warn "$sql;\n";

	my @columns;
	while(my ($c) = $sth->fetchrow_array()) {
		push @columns, $c;
	}

	return @columns;
}

# instantiates a new look-and-feel object unless one already exists
sub lf {
	my $self = shift;

	unless($self->{lf}) {
		$self->{lf} = Jaeger::Base::Lookfeel();
	}

	return $self->{lf};
}

# instantiates a new CGI query object unless one already exists
sub query {
	my $self = shift;

	unless($self->{query}) {
		$self->{query} = Jaeger::Base::Query();
	}

	return $self->{query};
}

# provide access to underscored functions
sub AUTOLOAD {
	my $obj = shift;
	my $varible = $Jaeger::Base::AUTOLOAD;
	$varible =~ s/.*:://;
	return if $varible eq 'DESTROY';
	if($varible =~ /^_/) {
		return;
	}
	my $value = shift;

	unless(ref $obj) {
		confess "hmm, $obj doesn't seem to be a reference (autoloading $Jaeger::Base::AUTOLOAD)\n";
	}

	if(exists $obj->{$varible}) {
		if(defined $value) {
			$obj->{$varible} = $value;
		}
		return $obj->{$varible};
	} else {
		unshift @_, $value;

		# maybe there's an underscored function to select it
		# we do this to only select things we actually need
		my $value = eval "\$obj->_$varible(\@_)";
		if($@) {
			carp "property $varible not found ($obj) ($@)";
		} else {
			return $value;
		}
	}
}

# determine the id of the current object
sub _id {
	my $self = shift;

	unless($self->{id}) {
		if($self->{oid} && $self->{table}) {
			my $sql = "select id from $self->{table} " .
				"where oid = $self->{oid}";
			my $sth = $self->{dbh}->prepare($sql);
			$sth->execute();
			$self->{id} = ($sth->fetchrow_array())[0];
		} else {
			# data hasn't been inserted
			return undef;
		}
	}

	return $self->{id};
}

# commit the data to the database
# (executes an INSERT or UPDATE as necessary)
sub update {
	my $self = shift;

	my $id = $self->id();
	my $rv;

	my @columns = grep !/^id$/, $self->columns();

	if($id) {
		# update
		my $sql = 'update ' . $self->table() . ' set ' .
			join(', ',
				map {"$_ = " . $self->{dbh}->quote($self->{$_})}
				@columns) .
			" where id = $id";

		$rv = $self->{dbh}->do($sql);
		unless($rv) {
			warn "$sql;\n";
		}

	} else {
		# insert
		my $sql = 'insert into ' . $self->table() . ' (' .
			join(', ', @columns) . ') values (' .
			join(', ',
				map {$self->{dbh}->quote($self->{$_})}
				@columns) . ')';

		my $sth = $self->{dbh}->prepare($sql);
		$rv = $sth->execute();
		unless($rv) {
			warn "$sql;\n";
		}
		$self->{oid} = $sth->{pg_oid_status};
	}

	return $rv;
}

# deletes the current object from the database
# ignores referential integrity and all that sort of good stuff
sub delete {
	my $self = shift;

	my $sql = 'delete from ' . $self->table() .
		' where id = ' . $self->id();

	my $rv = $self->{dbh}->do($sql);
	unless($rv) {
		warn "$sql;\n";
	}

	return $rv;
}

# returns unix time for the given Postgres timestamp
sub parsetimestamp {
	my $self = shift;

	my $timestamp = shift;

	my $sql = "select extract(epoch from timestamp '$timestamp')";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute
		or warn "$sql;\n";

	return ($sth->fetchrow_array())[0];
}

# this function should be overridden to return the real date for this entry
sub _date {
	my $self = shift;

	return undef;
}

# returns a Postgres-compatible date value for today
sub now {
	my $self = shift;

	my @date = localtime;

	return sprintf "%04d-%02d-%02d",
		$date[5] + 1900, $date[4] + 1, $date[3];
}

# print a http redirect header and exit
sub redirect {
	my $self = shift;

	foreach my $cookie (@{$self->lf()->{cookies}}) {
		print "Set-Cookie: $cookie\n";
	}
	my $url = shift;
	unless($url =~ /^http/) {
		$url = $Jaeger::Base::BaseURL . $url;
	}
	print $self->query()->redirect($url);

	exit;
}

# returns only one parameter
sub _Quote {
	$_ = shift;
	if(/ /) {
		s/"/\\"/g;
		return "\"$_\"";
	} else {
		return $_;
	}
}

# returns an array or one element, depending on what is requested
sub Quote {
	if(defined wantarray) {
		if(wantarray) {
			my @output = @_;
			foreach (@output) {
				$_ = _Quote($_);
			}
			return @output;
		} else {
			return _Quote(@_);
		}
	}
}

1;
