package		Jaeger::Lookfeel;

#
# $Id: Lookfeel.pm,v 1.26 2006-06-22 03:00:44 jaeger Exp $
#

#	Copyright (c) 1999-2002 Ted Logan (jaeger@festing.org)

# 06 May 1999 Ted Logan <jaeger@festing.org>
# modified 07 June 1999 for x13
# modified 29 August 1999 to use x13::Base
# modified 28 May 2000 for jaegerfesting
# updated 18 May 2002

use strict;

use Jaeger::Base;

use Jaeger::Journal;
use Jaeger::Changelog;
use Jaeger::Content;
use Jaeger::Event;
use Jaeger::User;

use Fortune;
use POSIX qw(ceil);

@Jaeger::Lookfeel::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;
	my $self = $package->SUPER::new(@_);

	$self->{static} = undef;

	return $self;
}

# grabs the appropiate field from the look and feel table
sub _lookfeel {
	my $self = shift;
	my $section = shift;

	my $sql = "select value from lookfeel where label = '$section'";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute();
	return ($sth->fetchrow_array)[0];
}

sub AUTOLOAD {
	my $self = shift;
	my $page = $Jaeger::Lookfeel::AUTOLOAD;
	$page =~ s/.*://;
	return if $page eq "DESTROY";
	return @_ if $page =~ /^_/;

	if(my $content = $self->_lookfeel($page)) {
		# we might have a section-specific thing we need to do
		my %params = eval "\$self->_$page(\@_)";
		if($@) {
			warn "lookfeel eval error: $@\n";
		}
		unless(%params) {
			%params = @_;
		}

		foreach my $p (keys %params) {
			$content =~ s/---$p---/$params{$p}/g;
		}

		$content =~ s/---\w*?---//g;
		return $content;
	} else {
		# content isn't in database; pass method on to master class
		return undef;
	}
}

# internal subs that manipulate the paramaters where necessary

sub _changelog {
	my $self = shift;

	my %params = @_;

	if($params{title}) {
		$params{title} = $self->changelog_title(
			title => $params{title}
		);
	}

	if($params{time_begin} && $params{time_end} &&
			($params{time_begin} ne $params{time_end})) {
		$params{timestamp} = $self->changelog_timeboth(
			time_begin => $params{time_begin},
			time_end => $params{time_end},
			visibility => $Jaeger::Changelog::Status{$params{status}},
		);
	} elsif($params{time_begin}) {
		$params{timestamp} = $self->changelog_timebegin(
			time_begin => $params{time_begin}
		);
	}

	return %params;
}

sub _comment {
	my $self = shift;

	my %params = @_;

	$params{date} =~ s/\..*//;

	return %params;
}

# we pass to this an array of objects to be displayed
# if more than one element is passed, the first one will be used only
# for the title and navigation links
sub _main {
	my $self = shift;
	my @obj = @_;
	my %params;

	if(my $title = $obj[0]->title()) {
		$params{title} = ": $title";
	}

	# set human-readable navigation links
	$params{navlinks} = $self->navlinks(
		prev => $obj[0]->prev(),
		index => $obj[0]->index(),
		next => $obj[0]->next(),
	);

	# set machine-readable navigation links
	my @navlink;
	if(my $prev = $obj[0]->prev()) {
		push @navlink, $self->navlink(
			type => 'prev',
			url => $prev->url(),
			title => $prev->title(),
		);
	}
	if(my $next = $obj[0]->next()) {
		push @navlink, $self->navlink(
			type => 'next',
			url => $next->url(),
			title => $next->title(),
		);
	}
	if(my $index = $obj[0]->index()) {
		push @navlink, $self->navlink(
			type => 'parent',
			url => $index->url(),
			title => $index->title(),
		);
	}
	$params{navlink} = join('', @navlink);

	# get a quote
	my $fortune = new Fortune;
	$fortune->read("$ENV{BCFS}/lib/quotes");

	my $quote = $fortune->quote();
	$quote =~ s/$/<br\/>/mg;

	$params{quote} = $quote;

	my @navbar;

	# the first "navigation box" will be the user logged-in status
	my $user = Jaeger::User->Login();

	if($user) {
		push @navbar, $self->login_status_user(user => $user->name());
	} else {
		push @navbar, $self->login_status_nonuser();
	}

	# populate the navigation links

	if(ref $obj[0] eq 'Jaeger::Changelog') {
		push @navbar, $obj[0]->Navbar();
	} else {
		push @navbar, Jaeger::Changelog->Navbar($obj[0]->date());
	}

	push @navbar, Jaeger::Comment->Navbar();

	if((ref $obj[0]) eq 'Jaeger::Content') {
		push @navbar, $obj[0]->Navbar();
	} else {
		push @navbar, Jaeger::Content->Navbar();
	}

	push @navbar, $self->rss_links();

	if($user) {
		push @navbar, eval "\$self->rss_links_$user->{login}()";
	}

	$params{navbar} = $self->links(linkbox => join('', @navbar));

	my $q = Jaeger::Base::Query();

	# populate content solutions data: links, chatterbox
	$params{links} = $self->search_box(q => $q->param('q'));
	$params{chatterbox} = $self->chatterbox(
		chatter => 'Coming soon, we hope'
	);

	# populate the content
	if(@obj > 1) {
		my @content;

		# the top element will be used only for title and nav links
		my $top = shift @obj;

		foreach my $object (@obj) {
			push @content, $object->html();
		}

		$params{content} = join '', @content;
	} else {
		$params{content} = $obj[0]->html();
	}

	if($user) {
		$params{rsscookie} = '?' . $user->cookie();
	}

	return %params;
}

sub _slideshow {
	my $self = shift;
	my $obj = shift;

	my %params;

	$params{title} = $obj->description();
	$params{round} = $obj->round();
	$params{number} = $obj->number();
	$params{size} = $obj->size();

	$params{next} = $obj->next()->url();
	$params{delay} = $self->query()->param('slideshow');

	return %params;
}

sub navlinks {
	my $self = shift;
	my %params = @_;

	unless(ref $params{prev} or ref $params{index} or ref $params{next}) {
		return;
	}

	my @link;

	if(ref $params{prev}) {
		push @link, '&lt; - <a href="' . $params{prev}->url() .
			'">Previous: ' . $params{prev}->title() . '</a>';
	} else {
		push @link, '&lt;- Previous';
	}

	if(ref $params{index}) {
		push @link, ' [ <a href="' . $params{index}->url() . '">' .
			$params{index}->title() . '</a> ] ';
	} else {
		push @link, ' [ Index ] ';
	}

	if(ref $params{next}) {
		push @link, '<a href="' . $params{next}->url() . '">Next: ' .
			$params{next}->title() . '</a> -&gt;';
	} else {
		push @link, 'Next -&gt;';
	}

	return join '', @link;
}

# content links
sub _content_link {
	my $self = shift;
	my %params = @_;

	if($params{current} eq $params{title}) {
		$params{class} = ' class="current"';
	}

	if(ref $params{children}) {
		my @children;
		push @children, "<ul>\n";
		foreach my $child (@{$params{children}}) {
			push @children, $self->content_link(
				current => $params{current},
				%$child
			);
		}
		push @children, "</ul>\n";
		$params{children} = join('', @children);
	}

	return %params;
}

# search stuff
sub _search_results {
	my $self = shift;

	my %params = @_;

	if($params{count} == 1) {
		$params{count} = '1 result';

	} elsif($params{count}) {
		# total number of pages
		my $totalpage = ceil($params{count} / $Jaeger::Search::Page);

		$params{count} = "$params{count} results; showing " .
			($params{page} * $Jaeger::Search::Page + 1) . ' to ' .
			(($params{page} + 1) * $Jaeger::Search::Page);

		# populate the page links

		# page range to show
		# (show at most 11 total page links 
		my $minpage = $params{page} > 5 ? $params{page} - 5 : 0;
		my $maxpage = $totalpage - $params{page} > 5 ?
			$params{page} + 5 : $totalpage;

		my @pages;

		if($minpage != 0) {
			push @pages, "&lt;&lt;&lt;\n";
		}

		# format the search query to nice url-encapsulation
		my $query = $params{q};
		$query =~ s/([^a-zA-Z0-9 ])/sprintf '%%%02x', ord($1)/ge;
		$query =~ s/ /+/g;

		for(my $i = $minpage; $i < $maxpage; $i++) {
			if($i == $params{page}) {
				push @pages, "[" . ($i + 1) ."]\n";
			} else {
				push @pages, $self->search_results_page(
					page => $i,
					pagenum => $i + 1,
					what => $params{what},
					q => $query,
				);
			}
		}

		if($maxpage != $totalpage) {
			push @pages, "&gt;&gt;&gt;\n";
		}

		$params{pages} = join('', @pages);

	} else {
		# no results at all
		$params{count} = 'no results';
	}

	return %params;
}

#
# User stuff
#

sub _user_view {
	my $self = shift;

	my %params = @_;

	$params{status} = $Jaeger::User::Status{$params{status}};

	$params{last_visit} =~ s/\..*//;

	# Select the user's comments
	my $status = 0;
	my $logged_in_user = Jaeger::User->Login();
	if($logged_in_user) {
		$status = $logged_in_user->status();
	}

	my @comments = Jaeger::Comment->Select("user_id = $params{id} and status <= $status order by date");
	if(@comments) {
		$params{comments} = "<small>\n" .
			join('', map {$self->user_comment_link(
				comment_url => $_->url(),
				comment_title => $_->title(),
				date => $_->date(),
				changelog_url => $_->changelog()->url(),
				changelog_title => $_->changelog()->title()
				)} @comments) .
			"</small>\n";
	} else {
		$params{comments} = '<i>(None)</i>';
	}

	return %params;
}

sub _user_list_item {
	my $self = shift;

	my %params = @_;

	$params{last_visit} =~ s/\..*//;

	return %params;
}

sub _user_comment_link {
	my $self = shift;
	my %params = @_;

	$params{date} =~ s/\..*//;

	return %params;
}

# yoda stuff

sub _yoda_item {
	my $self = shift;
	my %params = @_;

	$params{ppg} = sprintf '$%.2f', $params{ppg};
	$params{gal} = sprintf '%.3f', $params{gal};
	$params{total} = sprintf '$%.2f', $params{total};
	if($params{mpg}) {
		$params{mpg} = sprintf '%.2f', $params{mpg};
	} else {
		$params{mpg} = 'n/a';
	}

	return %params;
}

sub _login_status_user {
	my $self = shift;

	my %params = @_;

	# Show upcoming calender events
	my @calender;

	foreach my $event (Jaeger::Event->Upcoming(Jaeger::User->Login())) {
		push @calender, $self->link(
			url => '',
			title => $event->{name},
			new => ' ' . $event->{date}
		);
	}

	if(@calender == 0) {
		push @calender, "(empty)";
	}

	$params{calender} = join '', @calender;

	# Assemble a list of recent visitors
	my $where = "last_visit > now() + '-1h' order by last_visit desc";
	my @recent;
	foreach my $user (Jaeger::User->Select($where)) {
		my $sec = time - $self->parsetimestamp($user->last_visit());

		my $when;
		if($sec < 1) {
			$when = ' (now)';
		} else {
			my $min = int($sec / 60);
			$sec = int($sec) % 60;

			$when = sprintf " %d:%02d ago", $min, $sec;
		}

		push @recent, $self->link(
			url => $user->url(),
			title => $user->name(),
			new => $when,
		);
	}

	$params{recent} = join('', @recent);

	return %params;
}

sub _comment_edit {
	my $self = shift;

	my %params = @_;

 	$params{body} =~ s/&/&amp;/g;
 	$params{body} =~ s/>/&gt;/g;
 	$params{body} =~ s/</&lt;/g;
 	$params{body} =~ s/"/&quot;/g;

	return %params;
}

sub _comment_preview {
	my $self = shift;

	my %params = @_;

	$params{body_submit} = Jaeger::Comment::Post->Escape($params{body});

	return %params;
}

sub _comment_link {
	my $self = shift;

	my %params = @_;

	$params{indent} = '&nbsp;&nbsp;&nbsp;' x $params{indent};
	$params{date} =~ s/\..*//;

	return %params;
}

sub _flight_row {
	my $self = shift;

	my %params = @_;

	$params{international} = $params{international} ? "Yes" : "No";

	return %params;
}

1;
