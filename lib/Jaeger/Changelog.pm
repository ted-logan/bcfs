package		Jaeger::Changelog;

#
# $Id: Changelog.pm,v 1.9 2003-01-31 21:21:30 jaeger Exp $
#

# changelog package for jaegerfesting

# 28 May 2000
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::Changelog::Browse;

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

	$self->{index}->{url} = "changelog.cgi?browse=$year";
	$self->{index}->{title} = 'Index';

	return $self->{index};
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

	my @changelogs = Jaeger::Changelog->Select('1=1 order by time_begin desc limit 5');

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

1;
