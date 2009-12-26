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
use Jaeger::Changelog::Browse;
use Jaeger::Photo;

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

	return scalar $package->Select("status <= $level order by time_end desc limit 1");
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
			print "Committed changelog: id=", $self->id(), "\n";
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
			print "Postponed changelog: id=", $self->id(), "\n";
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

	print "Set status: $self->{status}: $Jaeger::Changelog::Status{$self->{status}}\n";

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

	$params{content} = $self->content();

	return $self->lf()->changelog(%params);
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

	my ($round) = $tag =~ /round="(\w+)"/;
	my ($number) = $tag =~ /number="(\w+)"/;

	my $photo = Jaeger::Photo->Select(
		round => $round,
		number => $number
	);

	if($photo) {
		# Make sure an appropiate thumbnail exists
		$photo->{size} = "320x240";
		$photo->resize();

		return $self->lf()->changelog_inline_photo(
			url => $photo->url(),
			round => $photo->round(),
			size => $photo->size(),
			number => $photo->number(),
			caption => $photo->description(),
		);
	}

	return undef;
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

1;
