package		Jaeger::Changelog;

#
# $Id: Changelog.pm,v 1.34 2008-06-28 19:07:33 jaeger Exp $
#

# changelog package for jaegerfesting

# 28 May 2000
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Comment;
use Jaeger::Comment::Post;
use Jaeger::Changelog::Browse;
use Jaeger::Changelog::Series;
use Jaeger::Changelog::Tag;
use Jaeger::Login;
use Jaeger::Notfound;
use Jaeger::PageRedirect;
use Jaeger::Photo;
use Jaeger::Photo::List::Date;
use Jaeger::Redirect;
use Jaeger::Uri;

use POSIX;

@Jaeger::Changelog::ISA = qw(Jaeger::Base);

%Jaeger::Changelog::Status = (
	0	=> 'World-readable',
	10	=> 'Logged-in users only',
	20	=> 'Friends &amp; Family only',
	22	=> 'Elite users only',
	25	=> 'Castor and Pollux only',
	30	=> 'Jaeger himself',
	100	=> 'Postponed'
);

sub Urimap {
	my ($uri, $user) = @_;

	my $changelog;

	if($uri =~ m#^//#) {
		# We ended up with one too many slashes at the beginning
		$uri =~ s#^/+#/#;
		$changelog = new Jaeger::Redirect($uri,
			Jaeger::Redirect::MOVED_PERMANENTLY);

	} elsif($uri =~ m#"$# || $uri =~ m#%22$#) {
		# A typo gave a link with an extra " at the end. Redirect to
		# the correct page.
		$uri =~ s/("|%22)$//;
		$changelog = new Jaeger::Redirect($uri,
			Jaeger::Redirect::MOVED_PERMANENTLY);

	} elsif($uri =~ m#/changelog/(\d+)\.html/reply#) {
		my $replyto = Jaeger::Changelog->new_id($1);
		if($user) {
			$changelog = new Jaeger::Redirect(
				$replyto->uri() . "/reply",
				Jaeger::Redirect::MOVED_PERMANENTLY);
		} else {
			$changelog = new Jaeger::Login(
				$replyto->uri() . "/reply");
		}

	} elsif($uri =~ m#/changelog/(\d+)\.html#) {
		# Show changelog by specific id
		$changelog = Jaeger::Changelog->new_id($1);
		if($changelog && $changelog->uri()) {
			# If a canonical uri is given, it will be different
			# than the id-based uri scheme. Redirect there instead.
			$changelog = new Jaeger::Redirect(
				$changelog->url(),
				Jaeger::Redirect::MOVED_PERMANENTLY);
		}

	} elsif($uri =~ m#/changelog/comment/(\d+)\.html/reply#) {
		# Post a reply to the comment
		my $replyto = Jaeger::Comment->new_id($1);
		if($replyto) {
			# Are we logged in?
			if($user) {
				$changelog = new Jaeger::Comment::Post(
					$replyto->changelog(), $replyto
				);
			} else {
				# Show a login page instead
				$changelog = new Jaeger::Login(
					"/changelog/comment/$1.html/reply");
			}
		}

	} elsif($uri =~ m#/changelog/comment/(\d+)\.html#) {
		# show a changelog comment
		$changelog = Jaeger::Comment->new_id($1);

	} elsif($uri =~ m#/changelog/(\d\d\d\d)(/?)$#) {
		# Browse changelogs by year
		my $year = $1;

		if($2) {
			# show the year itself
			$changelog = new Jaeger::Changelog::Browse($year);
		} else {
			# redirect to the "directory"
			$changelog = Jaeger::Redirect("/changelog/$1/",
				Jaeger::Redirect::MOVED_PERMANENTLY);
		}

	} elsif($uri =~ m#/changelog/tag/([^/]+)/?#) {
		# Show a list of changelogs attached to a particular tag
		$changelog = Jaeger::Changelog::Tag->new($1);

	} elsif($uri =~ m#/changelog/tag/?#) {
		# Show a list of all tags used by changelog
		$changelog = Jaeger::Changelog::Tag->new();

	} elsif($uri =~ m#/series/(\d+)(/?)#) {
		# Show a list of changelogs in a particular series
		$changelog = Jaeger::Changelog::Series->new_id($1);

	} elsif($uri eq '/changelog/' or $uri eq '/changelog') {
		# Show the most recent changelog
		my $latest = Newest Jaeger::Changelog;
		$changelog = new Jaeger::Redirect($latest->url());

	} elsif($uri =~ m#(/changelog/.*)/reply#) {
		# Post a reply to the changelog
		my $replyto = Jaeger::Changelog->Select(uri => $1);
		if($replyto) {
			# Are we logged in?
			if($user) {
				$changelog = new Jaeger::Comment::Post($replyto);
			} else {
				# Show a login page instead
				$changelog = new Jaeger::Login(
					$replyto->uri() . "/reply");
			}
		}

	} else {
		$uri =~ s/\?.*//;
		$changelog = Jaeger::Changelog->Select(uri => $uri);
		unless($changelog) {
			my $redirect = Jaeger::PageRedirect->Select(
				uri => $uri);
			if($redirect) {
				$changelog = new Jaeger::Redirect(
					$redirect->{redirect},
					Jaeger::Redirect::MOVED_PERMANENTLY);
			}
		}
	}

	unless($changelog) {
		$changelog = new Jaeger::Notfound;
	}

	# Check to see if we have access to this changelog or comment
	my $level = $user ? $user->{status} : 0;

	if(ref($changelog) && $changelog->{status} > $level) {
		# No access -- show a login page instead
		$changelog = new Jaeger::Login($changelog->url());
	}

	return $changelog;
}

sub table {
	return 'changelog';
}

sub update {
	my $self = shift;

	my %options = @_;

	if($self->{olduri}) {
		print "Adding redirect from $self->{olduri} to $self->{uri}\n";
		my $redirect = new Jaeger::PageRedirect();
		$redirect->{uri} = $self->{olduri};
		$redirect->{redirect} = $self->{uri};
		$redirect->update();
		$self->{olduri} = undef;
	}

	if($self->{key_date}) {
		$self->{sort_date} = $self->{key_date};
	} else {
		$self->{sort_date} = $self->{time_begin};
	}

	# Update first, so we always have an id
	my $rv = $self->SUPER::update();

	# Check if any tags were changed; and if so, make the appropriate
	# changes in the database
	if($self->{tags}) {
		my @new_tags;
		foreach my $tag (@{$self->{tags}}) {
			unless(grep {$_ eq $tag} @{$self->{_tags}}) {
				$self->add_tag($tag);
			}
		}

		my @delete_tags;
		foreach my $tag (@{$self->{_tags}}) {
			unless(grep {$_ eq $tag} @{$self->{tags}}) {
				push @delete_tags, $tag;
			}
		}
		if(@delete_tags) {
			my $sql = "delete from changelog_tag_map " .
				"where changelog_id = $self->{id} and " .
				"tag_id in (" .
				"select id from tag where name in (" .
				join(', ', map {"'$_'"} @delete_tags) . "))";
			Jaeger::Base::Pgdbh()->do($sql)
				or warn "Delete tags: $sql;\n";
		}

		$self->{_tags} = $self->{tags};
	}

	unless($options{skip_photo}) {
		$self->update_photo_xref();
	}

	return $rv;
}

sub add_tag {
	my $self = shift;
	my $tag = shift;

	my $id;
	do {
		my $sql = "select id from tag where name = '" . $tag . "'";
		my $tag_id = Jaeger::Base::Pgdbh()->selectcol_arrayref($sql);
		if($tag_id && defined($tag_id->[0])) {
			$id = $tag_id->[0];
		} else {
			my $sql = "insert into tag (name) values ('" .
				$tag . "')";
			unless(Jaeger::Base::Pgdbh()->do($sql)) {
				warn "Insert tag: $sql;\n";
				return;
			}
		}
	} while(!defined $id);

	# Now that we have the tag id, insert it
	my $sql = "insert into changelog_tag_map " .
		"values ($id, $self->{id})";
	Jaeger::Base::Pgdbh()->do($sql)
		or warn "Add tag $tag: $sql;\n";
}

sub find_key_date {
	my $self = shift;

	# If the summary starts with a date (in the form "1st January 2019" or
	# "1 January 2019"), this is the key date.
	if($self->{summary} =~ /^((\d+)(st|nd|rd|th)? (\w+) (\d+))/) {
		# TODO surely there's a better way to parse the date than this
		# :-/
		for(my $month = 1; $month < @Jaeger::Base::Months; $month++) {
			if($Jaeger::Base::Months[$month] eq $4) {
				return sprintf "%4d-%02d-%02d", $5, $month, $2;
			}
		}
	}

	return undef;
}

sub create_uri {
	my $self = shift;

	my $time_begin = $self->parsetimestamp($self->time_begin());

	my $date;
	if($self->key_date()) {
		$date = $self->key_date();
		$date =~ s/-/\//g;
	} else {
		$date = POSIX::strftime("%Y/%m/%d", localtime $time_begin);
	}

	my $title = Jaeger::Uri::MakeUriFromTitle($self->title());

	unless($title) {
		# Very old changelogs have no title. Make sure we have unique
		# names by including the time as well.
		$title = POSIX::strftime("%H-%M-%S", localtime $time_begin);
	}

	return '/changelog/' . $date . '/' . $title;
}

# returns the newest changelog
sub Newest {
	my $package = shift;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	return scalar $package->Select("status <= $level order by time_end desc limit 1");
}

# selects a changelog based on its old id
# (this enables backwards compatibility from old links)
sub old_id {
	my $package = shift;

	my $id_old = shift;

	return $package->Select(id_old => $id_old);
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
			my $tempfile = "$ENV{HOME}/changelog-" .
				POSIX::strftime("%Y-%m-%d-%H:%M:%S",
				       	localtime(time)) .
				".html";
			$self->export_file($tempfile);
			# submit the changelog into the global Content
			# Solutions Infrastructure
			if($self->update()) {
				unlink $tempfile;
				print "Committed changelog: id=", $self->id(),
			       		"\n";
				return 1;
			}

		} elsif($option eq 'i') {
			# ispell
			$self->_edit_pipe('ispell');

		} elsif($option eq 'e') {
			# edit
			$self->_edit_pipe(qq(vi "+set textwidth=72"));

		} elsif($option eq 'a') {
			# Set the access level for the changelog
			$self->_edit_level();

		} elsif($option eq 'q') {
			# abandon the changelog
			return 0;

		} elsif($option eq 'p') {
			# postpone this changelog for later viewing
			$self->{status} = 100;
			$self->update();
			print "Postponed changelog: id=", $self->id(), "\n";
			return 1;
		} elsif($option eq 's') {
			$self->_edit_series();
		}
	}
	
}

# Prompt the user at the command line to add/edit the serieses of which this
# changelog is a member
sub _edit_series {
	my $self = shift;

	print "\n";

	unless($self->{id}) {
		print "Cannot edit series information until the changelog is submitted\n";
		return;
	}

	my %my_serieses = map { $_->id(), $_ }
		Jaeger::Changelog::Series->new_by_changelog($self);

	if(%my_serieses) {
		print "This changelog is part of the following series:\n";
		foreach my $s (values %my_serieses) {
			print "* ", $s->name(), "\n";
		}
	} else {
		print "This changelog is not part of any series.\n";
	}

	my @all_serieses = Jaeger::Changelog::Series->Select();
	my %all_serieses = map { $_->id(), $_ } @all_serieses;

	my %legal_options = (
		a => 'Add this changelog to a series',
#		e => 'Edit the order of this changelog in a series',
		r => 'Remove this changelog from a series',
		q => 'Done with series',
	);

	do {
		print "\nYour series options:\n";
		foreach my $letter (sort keys %legal_options) {
			print "($letter) $legal_options{$letter}\n";
		}

		print "Your choice, master?\n> ";

		my $option;
		do {
			$option = lc <STDIN>;
			chomp $option;
		} while(!exists $legal_options{$option});

		print "\n";

		if($option eq 'a') {
			print "ID  Name\n";
			print "--  ----\n";
			foreach my $s (@all_serieses) {
				printf "%2d  %s\n",
					$s->id(), $s->name();
			}
			print " n  Create a new series\n";
			print "\n";

			print "Enter the series id to add this changelog to:\n";
			print "> ";
			my $id = <STDIN>;
			chomp $id;

			if(lc($id) eq 'n') {
				print "Enter the new series name to add:\n";
				print "> ";
				my $name = <STDIN>;
				chomp $name;

				unless($name) {
					next;
				}

				my $new_series = new Jaeger::Changelog::Series;
				$new_series->{name} = $name;
				if(!$new_series->update()) {
					print "Unable to add new series\n";
					next;
				}

				if(!$new_series->add_changelog($self, 1)) {
					print "Unable to add changelog to series\n";
					next;
				}
				next;
			}

			unless($all_serieses{$id}) {
				print "Invalid series id \"$id\"\n";
				next;
			}
			my $series = $all_serieses{$id};

			print "Order  Title\n";
			print "-----  -----\n";

			my $dbh = Jaeger::Base::Pgdbh();
			my $sql = "select sort_order, title " .
				"from changelog_series_entry " .
				"join changelog on changelog.id = changelog_series_entry.changelog_id " .
				"where series_id = $id order by sort_order";
			my $changelogs = $dbh->selectall_arrayref($sql);

			foreach my $c (@$changelogs) {
				printf "%5d  %s\n",
					$c->[0],
					$c->[1];
			}
			print "\n";

			print "Enter the position (empty to append):\n";
			print "> ";
			my $pos = <STDIN>;
			chomp $pos;

			unless($pos =~ /^\d*$/) {
				print "Invalid position \"$pos\"\n";
				next;
			}

			if(!$series->add_changelog($self, $pos)) {
				print "Unable to add changelog to series\n";
				next;
			}

			print "Added changelog to series \"", $series->name(),
				"\"\n";
			$my_serieses{$series->id()} = $series;

		} elsif($option eq 'e') {
			my $series;
			if((keys %my_serieses) == 0) {
				print "No series to edit\n";
				next;
			} elsif((keys %my_serieses) > 1) {
				
			} else {
				$series = (values %my_serieses)[0];
			}

		} elsif($option eq 'r') {
			my $series;
			if((keys %my_serieses) == 0) {
				print "No series to remove from\n";
				next;
			} elsif((keys %my_serieses) > 1) {
				print "ID  Name\n";
				print "--  ----\n";
				foreach my $s (values %my_serieses) {
					printf "%2d  %s\n",
						$s->id(), $s->name();
				}
				print "\n";

				print "Enter the series id to remove from this changelog to:\n";
				print "> ";
				my $id = <STDIN>;
				chomp $id;

				if(!$my_serieses{$id}) {
					print "This changelog is not part of series $id\n";
					next;
				}
				$series = $my_serieses{$id};

			} else {
				$series = (values %my_serieses)[0];
			}

			if(!$series->delete_changelog($self)) {
				print "Unable to remove changelog from series\n";
				next;
			}

			print "Removed changelog from series \"", $series->name(),
				"\"\n";
			delete $my_serieses{$series->id()};

		} elsif($option eq 'q') {
			return;
		}
	} while(1);
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

	if(!$self->{uri} && $self->{title} && $self->{time_begin}) {
		$self->{uri} = $self->create_uri();
	}

	$self->export_file($tempfile);

	system "$command $tempfile";

	my $changed = $self->import_file($tempfile);

	if($unlink_tempfile) {
		unlink $tempfile;
	}

	return $changed;
}

sub _edit_menu {
	my $self = shift;

	my %legal_options = (
		y => 'Contribute the changelog to the Content Solutions infrastructure',
		i => 'Sic ispell(1) on your horrible spelling',
		e => 'Edit the changelog',
		q => 'Abandon the changelog',
		p => 'Postpone the changelog',
		a => 'Set the access level',
		s => 'Edit series',
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

sub _edit_level {
	my $self = shift;

	$self->{status} = 0 unless $self->{status};

	print "\n";
	print "Access level is currently $self->{status}: $Jaeger::Changelog::Status{$self->{status}}\n";

	while(1) {
		print "New status: [$self->{status}] ";

		my $status = <STDIN>;
		chomp $status;

		if(defined $status) {
			if($Jaeger::Changelog::Status{$status}) {
				$self->{status} = $status;
				last;
			} else {
				print "Invalid status!\n";
			}
		} else {
			# status is unchanged
			last;
		}
	}

	print "Set status: $self->{status}: $Jaeger::Changelog::Status{$self->{status}}\n";

	return $self->{status};
}

# Import the changelog from a file on disk. This is used both for offline
# changelogs, and for live-editing changelogs.
sub import_file {
	my $self = shift;

	my $filename = shift;

	open my $fh, $filename
		or die "Can't open changelog $filename: $!\n";

	my %header;
	while(<$fh>) {
		s/[\r\n]+$//;
		last unless $_;
		my ($key, $value) = /(.*?):\s*(.*)/;
		$header{lc $key} = $value;
	}

	local $/ = undef;
	my $new_content = <$fh>;
	close $fh;

	my $changed = 0;

	if($header{title} && ($header{title} ne $self->{title})) {
		$self->{title} = $header{title};
		$changed = 1;
	}

	if($header{begin} && ($header{begin} ne $self->{time_begin})) {
		$self->{time_begin} = $header{begin};
		$changed = 1;
	}

	if($header{end} && ($header{end} ne $self->{time_end})) {
		$self->{time_end} = $header{end};
		$changed = 1;
	}

	if($header{date} ne $self->{key_date}) {
		$self->{key_date} = $header{date};
		$changed = 1;
	}
	if(!$self->{key_date}) {
		$self->{key_date} = $self->find_key_date();
	}

	if(exists $header{uri} && ($header{uri} ne $self->{uri})) {
		if($self->{uri} && !$self->{olduri}) {
			# If the uri changes, be prepared to create a redirect
			# from the old uri to the new uri. This redirect is
			# created when the changelog is updated.
			$self->{olduri} = $self->{uri};
		}
		$self->{uri} = $header{uri};
		$changed = 1;
	}
	
	if(!$self->{uri} && $self->{title} && $self->{time_begin}) {
		my $uri = $self->create_uri();
		if($self->{uri} ne $uri) {
			print "Calculated new uri: $uri\n";
			$self->{uri} = $uri;
			$changed = 1;
		}
	}

	if($header{summary} && ($header{summary} ne $self->{summary})) {
		$self->{summary} = $header{summary};
		$changed = 1;
	}

	if(exists $header{status} && ($header{status} != $self->{status})) {
		$self->{status} = $header{status};
		$changed = 1;
	}

	if(exists $header{tags} &&
			($header{tags} ne join(' ', @{$self->tags()}))) {
		$self->{tags} = [split /\s+/, lc $header{tags}];
		$changed = 1;
	}

	if($new_content ne $self->{content}) {
		$self->{content} = $new_content;
		$changed = 1;
	}

	return $changed;
}

sub export_file {
	my $self = shift;
	my $filename = shift;

	open TEMPFILE, ">$filename"
		or die "Can't write to tempfile: $!\n";
	print TEMPFILE "Title:  \t$self->{title}\n";
	print TEMPFILE "Begin:  \t$self->{time_begin}\n";
	print TEMPFILE "End:    \t$self->{time_end}\n";
	print TEMPFILE "Date:   \t$self->{key_date}\n";
	print TEMPFILE "Uri:    \t$self->{uri}\n";
	print TEMPFILE "Status: \t$self->{status}\n";
	print TEMPFILE "Summary:\t$self->{summary}\n";
	print TEMPFILE "Tags:   \t", join(' ', @{$self->tags()}), "\n";
	print TEMPFILE "\n";
	print TEMPFILE $self->{content};
	close TEMPFILE;
}

sub columns {
	my $self = shift;

	my @columns = $self->SUPER::columns();

	unless($self->{time_end}) {
		@columns = grep !/time_end/, @columns;
	}

	return @columns;
}

# returns an object for the previous changelog, if any
sub _prev {
	my $self = shift;

	unless($self->{time_begin}) {
		return undef;
	}

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	$self->{prev} = $self->Select("time_begin = (select max(time_begin) from changelog where time_begin < '$self->{time_begin}' and status <= $level)");

	return $self->{prev};
}

# returns an object for the next changelog, if any
sub _next {
	my $self = shift;

	unless($self->{time_begin}) {
		return undef;
	}

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	$self->{next} = $self->Select("time_begin = (select min(time_begin) from changelog where time_begin > '$self->{time_begin}' and status <= $level)");

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
	if($self->{uri}) {
		my $baseurl = $Jaeger::Base::BaseURL;
		$baseurl =~ s#/$##;
		return $self->{url} = $baseurl . $self->{uri};
	} else {
		return $self->{url} = $Jaeger::Base::BaseURL .
			"changelog/$self->{id}.html";
	}
}

sub _link {
	my $self = shift;

	return $self->{link} = '<a href="' . $self->url() . '">' .
		$self->title() . '</a>';
}

# returns html for this object
sub _html {
	my $self = shift;

	# If we're logged in, log this changelog access
	my $user = Jaeger::User->Login();
	if($user) {
		$user->log_access($self);
	}

	my %params = %$self;

	if(@{$self->tags()}) {
		$params{navigation} .= $self->lf()->changelog_tags(
			tags => join(' ', map {"<a href=\"/changelog/tag/$_\">$_</a>"} @{$self->tags()}),
		);
	}

	my @serieses = Jaeger::Changelog::Series->new_by_changelog($self);
	foreach my $series (@serieses) {
		$params{navigation} .= $self->lf()->changelog_series(
			changelog => $self,
			series => $series
		);
	}

	my $reply = $self->uri() . "/reply#reply";

	if($user) {
		# show the users who have viewed the changelog
		$params{navigation} .= '<p>These people have read this changelog: ' . join(', ', map {$_->link()} sort {$a->{name} cmp $b->{name}} @{$self->user_views()}) . '</p>';

		# Invite the user to post a comment
		$params{navigation} .= qq'<p><a href="$reply">Post comment</a></p>';
	} else {
		# Invite the user to log in to post
		$reply =~ s/#/%23/;
		$params{navigation} .= qq'<p><a href="/login.cgi?redirect=$reply" rel="nofollow">Log In</a> to post a comment.</p>';
	}

	# show the comments attached to this changelog
	$params{navigation} .= $self->comment_list_html();

	$params{content} = $self->content();

	return $self->lf()->changelog(%params);
}

sub fetch_inline_photo_tag {
	my $self = shift;
	my $tag = shift;

	my ($round) = $tag =~ /round="(\w+)"/;
	my ($number) = $tag =~ /number="(\w+)"/;
	my ($uri) = $tag =~ /uri="(.*?)"/;

	my $photo;
	if($round && $number) {
		$photo = Jaeger::Photo->Select(
			round => $round,
			number => $number
		);
	} elsif($uri) {
		$photo = Jaeger::Photo->Select(
			uri => $uri
		);
	}

	return $photo;
}

# Perform any last-minute text manipulations necessary to render the changelog
# as html.
sub content {
	my $self = shift;

	my $content = $self->{content};

	$content =~ s/(<photo .*?\/>)/$self->inline_photo($1)/ge;

	return $content;
}

# Renders an inline photo based on the <photo> pseudo-tag in the changelog body.
sub inline_photo {
	my $self = shift;
	my $tag = shift;

	my $photo = $self->fetch_inline_photo_tag($tag);

	if($photo) {
		# Make sure an appropiate thumbnail exists
		$photo->{size} = $Jaeger::Photo::ChangelogEmbedSize;
		$photo->resize();

		my $photo_icon_sphere;
		if($photo->has_photosphere()) {
			$photo_icon_sphere = $self->lf()->photo_icon_sphere();
		}

		return $self->lf()->changelog_inline_photo(
			url => $photo->url(),
			round => $photo->round(),
			size => $photo->size(),
			number => $photo->number(),
			caption => $photo->description(),
			photo_icon_sphere => $photo_icon_sphere,
		);
	}

	return undef;
}

# Look for the first <photo/> in the changelog, and use that as the summary
# image. I can think of places where the first image is not the most obvious
# image to use, but this will at least get us going.
sub _image {
	my $self = shift;

	if($self->{content} =~ /(<photo .*?\/>)/) {
		return $self->fetch_inline_photo_tag($1);
	}

	return undef;
}

sub update_photo_xref {
	my $self = shift;

	# All of the photos referenced in this changelog via a "<photo>" tag
	my %photos;

	print "Looking for photo cross-references for ", $self->id(), "...\n";

	my $content = $self->{content};
	while($content =~ /(<photo .*?\/>)/g) {
		my $tag = $1;

		if($tag =~ /nofollow/) {
			# Add a tag like 'rel="nofollow"' to signal that the
			# image is being used as a spacer or an illustration or
			# something, and we shouldn't generate a cross-
			# reference here.
			print "Skipping $tag\n";
			next;
		}

		my $photo = $self->fetch_inline_photo_tag($tag);

		if(!defined($photo) || $photo->hidden()) {
			warn "Changelog ", $self->id(),
				" references missing photo $tag\n";
		} else {
			if($photos{$photo->id()}) {
				warn "Changelog ", $self->id(),
					" references photo ", $photo->uri(),
					" multiple times\n";
			} else {
				$photos{$photo->id()} = $photo;
				# Make sure the photo is resized for the
				# correct size to be embedded in the changelog
				# before the changelog is posted
				$photo->remote_resize(
					$Jaeger::Photo::ChangelogEmbedSize);
			}
		}
	}

	my @days;

	if($self->key_date()) {
		push @days, $self->key_date();
	} elsif(my $key_date = $self->find_key_date()) {
		print "Found summary referencing date: $key_date\n";
		push @days, $key_date;
	}

	# TODO also consider links to all photos on a single day (but consider
	# the related case where this isn't a relevant cross-reference)
	while($content =~ /photo\.cgi\?date=(\d\d\d\d-\d\d-\d\d)/g) {
		print "Found link referencing date: $1\n";
		push @days, $1;
	}
	while($content =~ m("/photo/(\d\d\d\d)/(\d\d)/(\d\d)/")g) {
		print "Found link referencing date: $1-$2-$3\n";
		push @days, "$1-$2-$3";
	}

	foreach my $day (@days) {
		# TODO note that this includes a user status query, which
		# defaults to status=0. Instead this should consider all photos
		# in the database, since this is being used to update data in
		# the database, and is filtered later when it's displayed.
		my $photos_by_date = Jaeger::Photo::List::Date->new($day);
		my ($photo_count_by_date, $new_photo_count_by_date);
		foreach my $photo (@{$photos_by_date->photos()}) {
			# Here it's ok if the photos here overlap the photos
			# we've already added to the list of relevant photos.
			$photo_count_by_date++;
			unless($photos{$photo->id()}) {
				$new_photo_count_by_date++;
			}
			$photos{$photo->id()} = $photo;
		}
		printf "Found %d photos total (%d new photos) for date %s\n",
			$photo_count_by_date, $new_photo_count_by_date, $day;
	}

	my $photo_xref = $self->dbh()->selectcol_arrayref(
		"select photo_id from photo_xref_map where changelog_id = " . $self->id());
	if(!defined($photo_xref) || $DBI::err) {
		warn "Can't select photo cross-references: $DBI::errstr";
		return undef;
	}

	foreach my $xref_id (keys %photos) {
		unless(grep {$_ == $xref_id} @$photo_xref) {
			my $sql = "insert into photo_xref_map values (" .
				"$xref_id, " . $self->id() . ")";
			print "Adding cross-reference to $xref_id\n";
			$self->dbh()->do($sql)
				or warn "Insert photo-changelog xref: $sql";
		}
	}

	my @delete_xref;
	foreach my $xref_id (@$photo_xref) {
		unless(grep {$_ == $xref_id} keys %photos) {
			my $sql = "delete from photo_xref_map where " .
				"photo_id = $xref_id and " .
				"changelog_id = " . $self->id();
			print "Deleting cross-reference to $xref_id\n";
			$self->dbh()->do($sql)
				or warn "Delete photo-changelog xref: $sql";
		}
	}

	return 1;
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

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	my @changelogs;
	
	if($date) {
		@changelogs = (
			reverse(Jaeger::Changelog->Select("status <= $level and time_begin >= '$date' order by time_begin limit 3")),
			Jaeger::Changelog->Select("status <= $level and time_begin < '$date' order by time_begin desc limit 4"),
		);
	} else {
		@changelogs = Jaeger::Changelog->Select("status <= $level order by time_begin desc limit 5");
	}

	# these are the changelog ids that haven't yet been read by the user
	my %unread;
	my $user = Jaeger::User->Login();
	if($user) {
		my $sql = "select id from changelog where time_begin > '" .
			$user->signup() . "' and id not in (select " .
			"changelog_id from user_changelog_view where user_id =".
			$user->id() . ")";
		my $sth = Jaeger::Base::Pgdbh()->prepare($sql);
		$sth->execute() or warn "$sql;\n";
		while(my ($id) = $sth->fetchrow_array()) {
			$unread{$id} = 1;
		}
	}

	my @links;

	foreach my $changelog (@changelogs) {
		if($id == $changelog->id()) {
			push @links, $lf->link_current(
				url => $changelog->url(),
				title => $changelog->title()
			);
		} else {
			my $new;
			if($unread{$changelog->id()}) {
				$new = ' New!';
			} else {
				my $cc = @{$changelog->comments()};
				if($cc == 1) {
					$new = " (1 comment)";
				} elsif($cc > 1) {
					$new = " ($cc comments)";
				}
			}
			push @links, $lf->link(
				url => $changelog->url(),
				title => $changelog->title(),
				new => $new,
			);
		}
	}

	return $lf->linkbox(
		url => '/changelog/',
		title => 'j&auml;gerfesting',
		links => join('', @links)
	);
}

# returns the identities of those who have viewed this changelog
sub _user_views {
	my $self = shift;

	return [] unless $self->id();

	my $where = 'id in (select distinct user_id from user_changelog_view where changelog_id = ' . $self->id() . ')';

	return $self->{user_views} = [Jaeger::User->Select($where)];
}

# Return all the comments attached to this changelog
sub _comments {
	my $self = shift;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	my $where = "status <= $level and changelog_id = " . $self->id();

	return $self->{comments} = [Jaeger::Comment->Select($where)];
}

# returns html listing a changelog's comments
sub comment_list_html {
	my $self = shift;

	my $comment = shift;

	my @html;

	if($comment) {
		push @html, $self->link();
		if($self->{time_end}) {
			push @html, " <i>($self->{time_end})</i><br>\n";
		} else {
			push @html, " <i>($self->{time_begin})</i><br>\n";
		}
	}

	my @comments = sort {$a->date() cmp $b->date()}
		@{$self->comments()};
	push @html, "<ul>\n";
	foreach my $comment (@comments) {
		unless($comment->response_to()) {
			push @html, $comment->responses_list_html();
		}
	}
	push @html, "</ul>\n";

	return join('', @html);
}

# Returns an RFC 822 date for the publication date (time_end)
sub _pubDate {
	my $self = shift;

	return $self->{pubDate} = POSIX::strftime("%a, %d %b %Y %H:%M:%S %z",
		localtime $self->parsetimestamp($self->time_end()));
}

sub _tags {
	my $self = shift;
	my $id = $self->id();

	unless($id) {
		return [];
	}

	my $sql = "select name from tag " .
		"join changelog_tag_map on tag.id = changelog_tag_map.tag_id " .
		"where changelog_id = $id";
	my $tags = Jaeger::Base::Pgdbh()->selectcol_arrayref($sql);

	warn "Changelog->tags(): $sql;\n" unless $tags;

	# Cache the tags from the database so we can compare them if we're
	# editing the entry
	$self->{_tags} = $tags;
	return $self->{tags} = $tags;
}

1;
