package		Jaeger::Changelog;

#
# $Id: Changelog.pm,v 1.27 2004-11-12 23:08:45 jaeger Exp $
#

# changelog package for jaegerfesting

# 28 May 2000
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::User;
use Jaeger::Comment;
use Jaeger::Changelog::Browse;

use Apache::Constants qw(OK DECLINED REDIRECT);
use Apache::File;
use Apache::Cookie;
use Apache::Request;

@Jaeger::Changelog::ISA = qw(Jaeger::Base);

%Jaeger::Changelog::Status = (
	0	=> 'World-readable',
	10	=> 'Logged-in users only',
	20	=> 'Elite users only',
	25	=> 'Castor and Pollux only',
	30	=> 'Jaeger himself',
	100	=> 'Postponed'
);

sub table {
	return 'changelog';
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

	return scalar $package->Select("status <= $level order by time_begin desc limit 1");
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

	return Jaeger::Changelog::Browse->new($year);
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
			return 1;
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
		a => 'Set the access level',
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

		if($status) {
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

	return $self->{status};
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

	$self->{prev} = $self->Select("status <= $level and time_begin = (select max(time_begin) from changelog where time_begin < '$self->{time_begin}')");

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

	$self->{next} = $self->Select("status <= $level and time_begin = (select min(time_begin) from changelog where time_begin > '$self->{time_begin}')");

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
	return $self->{url} = $Jaeger::Base::BaseURL . "changelog/$self->{id}.html";
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

	if($user) {
		# show the users who have viewed the changelog
		$params{navigation} = '<p>These people have read this changelog: ' . join(', ', map {$_->link()} sort {$a->{name} cmp $b->{name}} @{$self->user_views()}) . '</p>';

		# Invite the user to post a comment
		$params{navigation} .= qq'<p><a href="/changelog/$self->{id}.html/reply">Post comment</a></p>';
	} else {
		# Invite the user to log in to post
		$params{navigation} .= '<p><a href="/login.cgi">Log In</a> to post a comment.</p>';
	}

	# show the comments attached to this changelog
	$params{navigation} .= $self->comment_list_html();

	return $self->lf()->changelog(%params);
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
		my $sth = $Jaeger::Base::Pgdbh->prepare($sql);
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
				} else {
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
	foreach my $comment (@comments) {
		unless($comment->response_to()) {
			push @html, $comment->responses_list_html(0);
		}
	}

	return join('', @html);
}

#
# mod_perl handler for changelogs (so we can get urls that don't end in
# .cgi so Google will index)
#
sub handler {
	my $r = shift;

	# clear the global cache of object ids in case any of them changed
	#
	# (There should be a better way to do this, to only the objects
	# that actually changed, but this is the simplest for now.)
	%Jaeger::Base::Ids = ();

	# does the file being requested exist, and is it not a directory?
	if(! -d $r->filename()) {
		my $fh = Apache::File->new($r->filename());
		if($fh) {
			if((my $rc = $r->meets_conditions()) != OK) {
				return $rc;
			}

			# Set useful http/1.1 headers
			$r->set_content_length();
			$r->set_etag();
			$r->set_last_modified((stat $r->finfo)[9]);

			$r->send_http_header();
			$r->send_fd($fh);
			return OK;
		}
	}

	$Jaeger::Base::Query = new Apache::Request($r);

	# Are we a logged-in user?
	my $user = undef;
	my %jar = Apache::Cookie->new($r)->parse();
	if($jar{jaeger_login} && $jar{jaeger_password}) {
		my $login = $jar{jaeger_login}->value();
		my $password = $jar{jaeger_password}->value();
		$user = Jaeger::User->Login($login, $password);
		if($user) {
			# send updated cookies
			$user->cookies();
		}
	} else {
		$Jaeger::User::Current = undef;
	}

	my $changelog;

	if($r->uri() =~ m#^//#) {
		# We ended up with one too many slashes at the beginning
		$changelog = $r->uri();
		$changelog =~ s#^/+#/#;

	} elsif($r->uri() =~ m#/changelog/(\d+)\.html$#) {
		# Show changelog by specific id
		$changelog = Jaeger::Changelog->new_id($1);
		unless($changelog) {
			$changelog = new Jaeger::Changelog;
			$changelog->{title} = 'No changelog';
			$changelog->{content} = 'No changelog was found with the given id';
		}

	} elsif($r->uri() =~ m#/changelog/(\d+)\.html/reply#) {
		# Post a reply to the changelog
		my $replyto = Jaeger::Changelog->new_id($1);
		if($replyto) {
			# Are we logged in?
			if($user) {
				$changelog = new Jaeger::Comment::Post($replyto);
			} else {
				# Redirect to the login page
				$changelog = "/login.cgi?redirect=/changelog/$1.html/reply";
			}


		} else {
			$changelog = new Jaeger::Changelog;
			$changelog->{title} = 'No changelog';
			$changelog->{content} = 'No changelog was found with the given id';
		}

	} elsif($r->uri() =~ m#/changelog/comment/(\d+)\.html/reply#) {
		# Post a reply to the comment
		my $replyto = Jaeger::Comment->new_id($1);
		if($replyto) {
			# Are we logged in?
			if($user) {
				$changelog = new Jaeger::Comment::Post(
					$replyto->changelog(), $replyto
				);
			} else {
				# Redirect to the login page
				$changelog = "/login.cgi?redirect=/changelog/comment/$1.html/reply";
			}

		} else {
			$changelog = new Jaeger::Changelog;
			$changelog->{title} = 'No comment';
			$changelog->{content} = 'No comment was found with the given id';
		}

	} elsif($r->uri() =~ m#/changelog/comment/(\d+)\.html#) {
		# show a changelog comment
		$changelog = Jaeger::Comment->new_id($1);
		unless($changelog) {
			$changelog = new Jaeger::Changelog;
			$changelog->{title} = 'No Comment';
			$changelog->{content} = 'No comment was found with the given id';
		}

	} elsif($r->uri() =~ m#/changelog/(\d\d\d\d)(/?)#) {
		# Browse changelogs by year
		my $year = $1;

		if($2) {
			# show the year itself
			$changelog = Jaeger::Changelog->Browse($year);
		} else {
			# redirect to the "directory"
			$changelog = "/changelog/$1/";
		}

	} elsif($r->uri() eq '/changelog/') {
		# Show the most recent changelog
		$changelog = Newest Jaeger::Changelog;

	} else {
		# quietly redirect to the most recent changelog
		$changelog = '/changelog/';
	}

	# Check to see if we have access to this changelog or comment
	my $level = $user ? $user->{status} : 0;

	if(ref($changelog) && $changelog->{status} > $level) {
		# No access -- quietly redirect
		$changelog = '/changelog/';
	}

	# Do we want to redirect to somewhere else?
	unless(ref $changelog) {
		warn "Redirecting to $changelog\n";

		$r->headers_out->set(Location => $changelog);

		return REDIRECT;
	}

	# If we're Googlebot, log this view.
	# 
	# (Don't use the normal method, which would present the bot with
	# the "you're now logged in" message and other stuff.)
	my $ua = $r->headers_in->get('User-Agent');
	if($ua =~ /googlebot/i) {
		my $googlebot = Jaeger::User->Select(login => 'googlebot');
		$googlebot->log_access($changelog);
		$googlebot->update_last_visit();
	}

	# Store the user's browser in the database
	if($user) {
		$user->{last_browser} = $ua;
		$user->update();
	}

	$r->send_http_header('text/html; charset=UTF-8');

	print Jaeger::Base::Lookfeel()->main($changelog);

	# Clean up after the logged-in user, since we're doing the sneaky
	# mod_perl thing

	$Jaeger::User::Current = 0;
	$Jaeger::Base::Query = undef;

	return OK;
}

1;
