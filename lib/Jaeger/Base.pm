package Jaeger::Base;

#
# $Id: Base.pm,v 1.10 2006-12-31 04:24:17 jaeger Exp $
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
use Log::Any qw($log), default_adapter => 'Stderr';

use CGI;

# Connect to the Postgres database running on Awn. Note that I've set up the
# database to expose a non-standard port (port 1284), since I've made the port
# accessible over the open internet so I can connect to it remotely without the
# cumbersome ssh tunnel.
#
# On awn (ie, when the hostname starts with awn), connect to localhost.
# On other hosts, connect to awn.festing.org.

my $connection = "host=awn.festing.org;port=1284;user=jaeger;";
$Jaeger::Base::BaseURL = 'https://jaeger.festing.org/';
my $hostname = `hostname`;
if($hostname =~ /^awn/) {
	# If we're on Awn, connect locally.
	$connection = "port=1284;";
}
if($ENV{SERVER_NAME}) {
	$Jaeger::Base::BaseURL = "https://$ENV{SERVER_NAME}/";
}

$Jaeger::Base::Pgdbh = undef;

sub Pgdbh {
	unless($Jaeger::Base::Pgdbh) {
		$Jaeger::Base::Pgdbh =
			DBI->connect("DBI:Pg:${connection}dbname=jaeger", "",
				"");
		unless($Jaeger::Base::Pgdbh) {
			die $log->fatal("Jaeger::Base: Unable to connect to pg database");
		}
	}
	return $Jaeger::Base::Pgdbh;
}

# Attempt to ping the database handle to see if it's still valid. If it's not,
# attempt to reconnect. This is useful in the event of a long-running
# interactive session where a connection was made before the machine running it
# was suspended and may have lost its network connection.
sub Pingdbh {
	if($Jaeger::Base::Pgdbh) {
		unless($Jaeger::Base::Pgdbh->ping()) {
			$log->info("Database handle invalid, attempting to reconnect");
			$Jaeger::Base::Pgdbh = undef;
			Pgdbh();
		}
	}
}

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

	$self->{dbh} = Jaeger::Base::Pgdbh();
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

# Creates a database query and returns an iterator that will select the next
# row from the database.
#
# Example:
#
# my $iter = Jaeger::Changelog->Prepare("status = 0 order by time_begin");
# while(my $changelog = $iter->next()) {
#   ...
# }
sub Prepare {
	my $package = shift;
	if(ref $package) {
		$package = ref $package;
	}

	my $dbh = Jaeger::Base::Pgdbh();

	my $whereclause;
	if(@_ == 1) {
		my $where = shift;
		if($where =~ /^join /i) {
			$whereclause = ' ' . $where;
		} else {
			$whereclause = ' where ' . $where;
		}
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

	my $sql = "select " . $package->table() . ".* from " .
		$package->table() . $whereclause;

	my $sth = $dbh->prepare($sql);
	$sth->execute()
		or $log->error("$sql;");

	return Jaeger::Base::Iterator->new($package, $sth);
}

# selects one or more objects from the relevant database
sub Select {
	my $package = shift;
	if(ref $package) {
		$package = ref $package;
	}

	my $iter = $package->Prepare(@_);

	# do we want just one, or multiple results?
	if(wantarray) {
		my @results;

		while(my $item = $iter->next()) {
			push @results, $item;
		}

		return @results;

	} else {
		return $iter->next();
	}
}

# returns the number of database rows corresponding to the selection query
sub Count {
	my $package = shift;

	my $dbh = Jaeger::Base::Pgdbh();

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
		or $log->error("$sql;");

	return ($sth->fetchrow_array())[0];
}

# in case the child doesn't actually have a table associated with it
sub table {
	return undef;
}

sub dbh {
	my $self = shift;

	return Jaeger::Base::Pgdbh();
}

# returns an array containing the columns in a table
sub columns {
	my $self = shift;

	my $sql = "select attname from pg_attribute where attrelid = " .
		"(select oid from pg_class where relname = '" . $self->table() .
		"') and attnum > 0";
	my $sth = $self->dbh()->prepare($sql);
	$sth->execute()
		or $log->error("$sql;");

	my @columns;
	while(my ($c) = $sth->fetchrow_array()) {
		unless($c =~ /pg\.dropped/) {
			push @columns, $c;
		}
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
		die $log->fatal("hmm, $obj doesn't seem to be a reference (autoloading $Jaeger::Base::AUTOLOAD)");
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
			$log->warn("property $varible not found ($obj) ($@)");
		} else {
			return $value;
		}
	}
}

# commit the data to the database
# (executes an INSERT or UPDATE as necessary)
sub update {
	my $self = shift;

	my $id = $self->id();
	my $rv;

	my @columns = grep !/^id$/, $self->columns();

	my $dbh = $self->dbh();

	if($id) {
		# update
		my $sql = 'update ' . $self->table() . ' set ' .
			join(', ',
				map {"$_ = " . $dbh->quote($self->{$_})}
				@columns) .
			" where id = $id";

		$rv = $dbh->do($sql);
		unless($rv) {
			$log->error("$sql;");
		}

	} else {
		# insert
		my $sql = 'insert into ' . $self->table() . ' (' .
			join(', ', @columns) . ') values (' .
			join(', ',
				map {$dbh->quote($self->{$_})}
				@columns) . ')';

		$rv = $dbh->do($sql);
		if($rv) {
			$self->{id} = $dbh->last_insert_id(
				undef, undef, $self->table(), undef
			);
		} else {
			$log->error("$sql;");
		}
	}

	return $rv;
}

# deletes the current object from the database
# ignores referential integrity and all that sort of good stuff
sub delete {
	my $self = shift;

	my $sql = 'delete from ' . $self->table() .
		' where id = ' . $self->id();

	my $rv = $self->dbh()->do($sql);
	unless($rv) {
		$log->error("$sql;");
	}

	return $rv;
}

# returns unix time for the given Postgres timestamp
sub parsetimestamp {
	my $self = shift;

	my $timestamp = shift;

	my $sql = "select extract(epoch from timestamp with time zone '$timestamp')";
	my $sth = $self->dbh()->prepare($sql);
	$sth->execute
		or $log->error("$sql;");

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
		$url =~ s#^/##;
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

package Jaeger::Base::Iterator;

sub new {
	my $package = shift;
	my $child = shift;
	my $sth = shift;

	my $self = {
		package => $child,
		sth => $sth,
	};

	return bless $self, $package;
}

sub next {
	my $self = shift;

	if(my $result = $self->{sth}->fetchrow_hashref()) {
		return $self->{package}->new($result);
	} else {
		return undef;
	}
}

1;
