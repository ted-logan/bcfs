package		Jaeger::Changelog;

#
# $Id: Changelog.pm,v 1.12 2003-08-24 20:58:08 jaeger Exp $
#

# changelog package for jaegerfesting

# 28 May 2000
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::User;
use Jaeger::Changelog::Browse;

use Apache::Constants qw(OK DECLINED REDIRECT);
use Apache::File;
use Apache::Cookie;

@Jaeger::Changelog::ISA = qw(Jaeger::Base);

sub table {
	return 'changelog';
}

# returns the newest changelog
sub Newest {
	my $package = shift;

	return scalar $package->Select('1=1 order by time_begin desc limit 1');
}

# selects a changelog based on its old id
# (this enables backwards compatibility from old links)
sub old_id {
	my $package = shift;

	my $id_old = shift;

	return $package->Select(id_old => $id_old);
}

# provides a list of changelogs by year
sub Browse {
	my $package = shift;

	my $year = shift;

	return new Jaeger::Changelog::Browse($year);
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
			$self->update();
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

	unless($self->{time_begin}) {
		die "Changelog is undefined; prev doesn't exist";
	}

	$self->{prev} = $self->Select("time_begin = (select max(time_begin) from changelog where time_begin < '$self->{time_begin}')");

	return $self->{prev};
}

# returns an object for the next changelog, if any
sub _next {
	my $self = shift;

	unless($self->{time_begin}) {
		die "Changelog is undefined; next doesn't exist";
	}

	$self->{next} = $self->Select("time_begin = (select min(time_begin) from changelog where time_begin > '$self->{time_begin}')");

	return $self->{next};
}

# returns a link to the index
sub _index {
	my $self = shift;

	my ($year) = $self->{time_begin} =~ /^(\d\d\d\d)-/;

	$self->{index} = new Jaeger::Base;

	$self->{index}->{url} = "/changelog/$year/";
	$self->{index}->{title} = 'Index';

	return $self->{index};
}

# returns a link to the url of this changelog
sub _url {
	my $self = shift;
#	return $self->{url} = "$self->{id}.html";
	return $self->{url} = "$Jaeger::Base::BaseURL/changelog/$self->{id}.html";
}

# returns html for this object
sub _html {
	my $self = shift;

	# If we're logged in, log this changelog access
	my $user = Jaeger::User->Login();
	if($user) {
		$user->log_access($self);
	}

	return $self->lf()->changelog(%$self);
}

# returns the Postgres-compatible date of this object so we can show related
# content
sub _date {
	my $self = shift;

	return $self->{date} = $self->{time_begin};
}

sub Navbar {
	my $package = shift;

	my ($lf, $id, $date);
	# this might be a class method, or might be an instance method
	if(ref $package) {
		$id = $package->id();
		$lf = $package->lf();
		$date = $package->date();
	} else {
		$id = 0;
		$lf = Jaeger::Base::Lookfeel();
		$date = shift;
	}

	my @changelogs;
	
	if($date) {
		@changelogs = (
			reverse(Jaeger::Changelog->Select("time_begin >= '$date' order by time_begin limit 3")),
			Jaeger::Changelog->Select("time_begin < '$date' order by time_begin desc limit 4"),
		);
	} else {
		@changelogs = Jaeger::Changelog->Select('1=1 order by time_begin desc limit 5');
	}

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
		url => '/changelog/',
		title => 'j&auml;gerfesting',
		links => join('', @links)
	);
}

#
# mod_perl handler for changelogs (so we can get urls that don't end in
# .cgi so Google will index)
#
sub handler {
	my $r = shift;

	# does the file being requested exist, and is it not a directory?
	if(! -d $r->filename()) {
		my $fh = Apache::File->new($r->filename());
		if($fh) {
			$r->send_http_header();
			$r->send_fd($fh);
			return OK;
		}
	}

	my $changelog;

	if($r->uri() =~ m#/changelog/(\d+)\.html$#) {
		# Show changelog by specific id
		$changelog = Jaeger::Changelog->new_id($1);
		unless($changelog) {
			$changelog = new Jaeger::Changelog;
			$changelog->{title} = 'No changelog';
			$changelog->{content} = 'No changelog was found with the given id';
		}
	
	} elsif($r->uri() =~ m#/changelog/(\d+)(/?)#) {
		# Browse changelogs by year
		my $year = $1;

		if($2) {
			# show the year itself
			$changelog = Jaeger::Changelog->Browse($year);
		} else {
			# redirect to the "directory"
			$r->headers_out->set(Location => "/changelog/$1/");

			return REDIRECT;
		}

	} elsif($r->uri() eq '/changelog/') {
		# Show the most recent changelog
		$changelog = Newest Jaeger::Changelog;

	} else {
		# quietly redirect to the most recent changelog
		$r->headers_out->set(Location => "/changelog/");

		return REDIRECT;
	}

	$r->send_http_header('text/html');

	# Are we a logged-in user?
	my %jar = Apache::Cookie->new($r)->parse();
	if($jar{jaeger_login} && $jar{jaeger_password}) {
		my $login = $jar{jaeger_login}->value();
		my $password = $jar{jaeger_password}->value();
		Jaeger::User->Login($login, $password);
	}

	print Jaeger::Base::Lookfeel()->main($changelog);

	# Clean up after the logged-in user, since we're doing the sneaky
	# mod_perl thing

	$Jaeger::User::Current = 0;

	return OK;
}

1;
