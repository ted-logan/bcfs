package		Jaeger::Changelog;

#
# $Id: Changelog.pm,v 1.4 2002-08-26 06:20:57 jaeger Exp $
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

# selects a changelog based on its old id
# (this enables backwards compatibility from old links)
sub old_id {
	my $package = shift;

	my $self = $package->SUPER::new();
  
	my $id_old = shift;
	if(defined $id_old) {
		$self->_db_select("where id_old = $id_old")
			or return;
	} else {
		return;
	}

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

# Use this only at the console
# Breaks out vim to edit the current changelog and presents a short menu
sub edit {
	my $self = shift;

	my $tempfile = shift;

	$self->_edit_pipe(qq(vi "+set textwidth=72"));

	while(1) {
		my $option = $self->_edit_menu();

		if($option eq 'y') {
			# submit the changelog into the global Content
			# Solutions Infrastructure
			$self->insert();
			return 1;

		} elsif($option eq 'i') {
			# ispell
			$self->_edit_pipe('ispell');

		} elsif($option eq 'e') {
			# edit
			$self->_edit_pipe(qq(vi "+set textwidth=72"));

		} elsif($option eq 'q') {
			# abandon the changelog
			return 0;

		} elsif($option eq 'p') {
			# postpone, which we don't support yet
		}
	}
	
}

# ensures a unique file name for each changelog we edit
$Jaeger::Changelog::Count = 0;

# breaks out vim to edit the changelog
# returns 1 if the content has changed at all
sub _edit_pipe {
	my $self = shift;

	my $command = shift;

	# should we update the started time?
	unless($self->{time_begin}) {
		$self->{time_begin} = scalar localtime time;
	}

	my $tempfile = shift;
	my $unlink_tempfile = 0;

	unless($tempfile) {
		$tempfile = "/tmp/article-$$-" . ($Jaeger::Changelog::Count++)
			. '.html';
		$unlink_tempfile = 1;
	}

	if($self->{content}) {
		open TEMPFILE, ">$tempfile"
			or die "Can't write to tempfile: $!\n";
		print TEMPFILE $self->{content};
		close TEMPFILE;
	}

	my $old_content = $self->{content};

	system "$command $tempfile";

	open TEMPFILE, $tempfile
		or die "Can't open tempfile: $!\n";
	local $/ = undef;
	my $new_content = <TEMPFILE>;
	close TEMPFILE;

	# should we update the finished time?
	unless($self->{time_end}) {
		$self->{time_end} = scalar localtime time;
	}

	if($unlink_tempfile) {
		unlink $tempfile;
	}

	$self->{content} = $new_content;

	if($new_content eq $old_content) {
		return 0;
	} else {
		return 1;
	}
}

sub _edit_menu {
	my $self = shift;

	my %legal_options = (
		y => 'Contribute the changelog to the Content Solutions infrastructure',
		i => 'Sic ispell(1) on your horrible spelling',
		e => 'Edit the changelog',
		q => 'Abandon the changelog',
		p => 'Postpone the changelog',
	);

	print "\nYour Changelogging options:\n";
	while(my ($letter, $value) = each %legal_options) {
		print "($letter) $value\n";
	}

	print "Your choice, master?\n> ";

	do {
		my $option = lc <STDIN>;
		chomp $option;
		if(exists $legal_options{$option}) {
			return $option;
		}
	} while(1);
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
#	return $self->{url} = "$self->{id}.html";
	return $self->{url} = "$Jaeger::Base::BaseURL/changelog.cgi?id=$self->{id}";
}

# returns html for this object
sub _html {
	my $self = shift;

	return $self->lf()->changelog(%$self);

}

sub Navbar {
	my $package = shift;

	my ($lf, $id);
	# this might be a class method, or might be an instance method
	if(ref $package) {
		$id = $package->id();
		$lf = $package->lf();
	} else {
		$id = 0;
		$lf = new Jaeger::Lookfeel;
	}

	my @changelogs = All Jaeger::Changelog(undef, 'time_begin desc', 5, 1);

	my @links;

	foreach my $changelog (@changelogs) {
		if($id == $changelog->id()) {
			push @links, $lf->link_current(
				url => $changelog->url(),
				title => $changelog->title()
			);
		} else {
			push @links, $lf->link(
				url => $changelog->url(),
				title => $changelog->title()
			);
		}
	}

	return $lf->linkbox(
		url => '/changelog.cgi',
		title => 'j&auml;gerfesting',
		links => join('', @links)
	);
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

1;
