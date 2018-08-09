package		Jaeger::Lookfeel;

#
# $Id: Lookfeel.pm,v 1.29 2007-03-01 02:58:00 jaeger Exp $
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
use Jaeger::Changelog::Browse;
use Jaeger::Changelog::Tag;
use Jaeger::Content;
use Jaeger::Event;
use Jaeger::Photo::Set;
use Jaeger::Photo::Year;
use Jaeger::Slideshow;
use Jaeger::User;

use Fortune;
use POSIX qw(ceil strftime);

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

		$content =~ s/---[a-zA-Z0-9_]+?---//g;
		$content =~
			s/https?:\/\/(alpha|beta|jaeger)\.festing\.org\//$Jaeger::Base::BaseURL/g;
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

	if($params{summary}) {
		$params{content} = '<blockquote><i>' . $params{summary} .
			"</i></blockquote>\n" . $params{content};
	}

	return %params;
}

sub _changelog_series {
	my $self = shift;

	my %params = @_;

	$params{name} = $params{series}->name();
	$params{description} = $params{series}->description();

	my @list;
	foreach my $changelog ($params{series}->changelogs()) {
		if($changelog->id() == $params{changelog}->id()) {
			push @list, '<b>' . $changelog->title() . '</b>';
		} else {
			push @list, $changelog->link();
		}
	}

	$params{changelogs} = '[ ' . join(' | ', @list) . ' ]';

	return %params;
}

sub _browse_changelog {
	my $self = shift;

	my $changelog = shift;

	my %params = (
		url => $changelog->url(),
		title => $changelog->title(),
		time_begin => $changelog->time_begin(),
		visibility => $Jaeger::Changelog::Status{$changelog->status()},
	);

	if($changelog->summary()) {
		$params{summary} = $self->browse_changelog_summary(
			summary => $changelog->summary()
		);
	}
	my $tags = $changelog->tags();
	if(@$tags) {
		$params{summary} .= $self->browse_changelog_summary(
			summary => "Tags: " . join(' ', map {"<a href=\"/changelog/tag/$_\">$_</a>"} @$tags),
		);
	}
	my @series = Jaeger::Changelog::Series->new_by_changelog($changelog);
	if(@series) {
		$params{summary} .= $self->browse_changelog_summary(
			summary => "Series: " . join(' ', map {$_->link()} @series),
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

sub screencss {
	my $self = shift;

	my $useragent;

	if(ref $self->query() eq 'CGI') {
		# Get the user agent from the CGI environment
		$useragent = $self->query()->user_agent();
	}
	if(ref $self->query() eq 'Apache2::Request') {
		$useragent = $self->query()->headers_in->get('User-Agent');
	}

	# If the user agent indicates this is a mobile browser, don't provide
	# the CSS designed for full-sized browsers.
	if($useragent !~ /iPhone/ && $useragent !~ /Mobile Safari/ &&
			$useragent !~ /IEMobile/ && $useragent !~ /Android/) {
		return '<link rel="stylesheet" href="/jaeger-screen.css" type="text/css"/>';
	} else {
		return <<HTML;
<link rel="stylesheet" href="/jaeger-mobile.css" type="text/css"/>
<meta name="viewport" content="width=device-width, user-scalable=no" />
HTML
	}
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
	push @navlink,
		'<meta name="twitter:card" content="summary" />';
	push @navlink,
		'<meta name="twitter:site" content="@calvinsdad" />';
	if(my $summary = $obj[0]->summary()) {
		# Summary should be plain text. Encode it.
		$summary =~ s/&/&amp;/g;
		$summary =~ s/"/&quot;/g;
		$summary =~ s/</&lt;/g;
		$summary =~ s/>/&gt;/g;
		push @navlink,
			qq'<meta name="description" content="$summary" />';
		push @navlink,
			qq'<meta name="twitter:description" content="$summary" />';
	}
	if(my $title = $obj[0]->title()) {
		$title =~ s/&/&amp;/g;
		$title =~ s/"/&quot;/g;
		$title =~ s/</&lt;/g;
		$title =~ s/>/&gt;/g;
		push @navlink,
			qq'<meta name="twitter:title" content="$title" />';
	}
	if(my $image = $obj[0]->image()) {
		my $size = "640x480";
		$image->resize($size);
		push @navlink,
			qq'<meta name="twitter:image" content="${Jaeger::Base::BaseURL}digitalpics/' . $image->round() . "/$size/" . $image->number() . '.jpg" />';
	}
	$params{navlink} = join("\n", @navlink);

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
		$params{mobilelogin} = qq'<a href="/logout.cgi">Log out</a>';
	} else {
		push @navbar, $self->login_status_nonuser();
		$params{mobilelogin} = qq'<a href="/login.cgi">Log in</a>';
	}

	# populate the navigation links

	my $q = Jaeger::Base::Query();

	push @navbar, $self->search_box(q => $q->param('q'));

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

	# These parameters are shown in the printable footer
	$params{date} = strftime "%H:%M %e %B %Y", localtime;
	if(ref $self->query() eq 'CGI') {
		$params{url} = $self->query()->url(-query => 1);
	}
	if(ref $self->query() eq 'Apache2::Request') {
		# There has to be a better way to get the full URL, right?
		my $baseurl = $Jaeger::Base::BaseURL;
		$baseurl =~ s#/$##;
		$params{url} = $baseurl . $self->query()->unparsed_uri();
	}

	$params{screencss} = $self->screencss();

	# Show the general nav bars on the right side of the screen, which
	# ought to provide an easy entry into my (changelog) content
	my $tags = new Jaeger::Changelog::Tag;
	$params{browsebytag} = $tags->mininav();

	my $browse = (ref $obj[0] eq 'Jaeger::Changelog::Browse') ?
		$obj[0] : new Jaeger::Changelog::Browse;
	$browse->{year} = 0;
	$params{browsebyyear} = $browse->mininav();

	my $photos = new Jaeger::Photo::Year;
	$params{photosbyyear} = $photos->mininav();

	my @photo_sets = sort {$a->{name} cmp $b->{name}}
		Jaeger::Photo::Set->Select();
	$params{photosets} = "<ul>" .
		join('', map { "<li><a href=\"" . $_->url() . "\">" .
			$_->name() . "</a></li>\n" } @photo_sets) . "</ul>\n";

	$params{analytics} = $self->analytics();

	return %params;
}

sub _photo_main {
	my $self = shift;
	my $obj = shift;

	my %params;

	my @navlink;
	if(my $title = $obj->title()) {
		$params{title} = ": $title";
		$params{description} = "$title.";
	}
	if(ref $obj eq 'Jaeger::Photo') {
		my $size = "640x480";
		$obj->resize($size);
		$params{photo} = ${Jaeger::Base::BaseURL} . 'digitalpics/' .
			$obj->round() . "/$size/" . $obj->number() . '.jpg';
	}

	# set human-readable navigation links
	$params{navlinks} = $self->navlinks(
		prev => $obj->prev(),
		index => $obj->index(),
		next => $obj->next(),
	);

	# set machine-readable navigation links
	if(my $prev = $obj->prev()) {
		push @navlink, $self->navlink(
			type => 'prev',
			url => $prev->url(),
			title => $prev->title(),
		);
	}
	if(my $next = $obj->next()) {
		push @navlink, $self->navlink(
			type => 'next',
			url => $next->url(),
			title => $next->title(),
		);
	}
	if(my $index = $obj->index()) {
		push @navlink, $self->navlink(
			type => 'parent',
			url => $index->url(),
			title => $index->title(),
		);
	}
	$params{navlink} = join('', @navlink);

	# Set mobile nav links
	if($obj->prev()) {
		$params{navprev} = $obj->prev()->url();
		$params{navprevtitle} = $obj->prev()->title();
	}
	if($obj->next()) {
		$params{navnext} = $obj->next()->url();
		$params{navnexttitle} = $obj->next()->title();
	}
	if($obj->index()) {
		$params{navup} = $obj->index()->url();
		$params{navuptext} = $obj->index()->title();
	} else {
		$params{navup} = "/photos.cgi";
		$params{navuptext} = "Photos";
	}

	$params{screencss} = $self->screencss();

	# Fill in the content from the photo itself
	$params{phototitle} = $obj->{description};
	$params{date} = $obj->date_format() || "&nbsp;";
	$params{round} = $obj->round();
	$params{number} = $obj->number();
	$params{size} = $obj->size();

	if($obj->status() > 0) {
		$params{date} .= " (" .
			$Jaeger::Changelog::Status{$obj->status()} .
			")";

	}

	if(defined($obj->{longitude}) && defined($obj->{latitude})) {
		$params{location} = $self->photo_coordinates(
			longitude => $obj->{longitude},
			latitude => $obj->{latitude},
		);
	}

	# If the user has the appropriate privilages, show the edit links
	my $status = 0;
	my $logged_in_user = Jaeger::User->Login();
	if($logged_in_user && $logged_in_user->status() >= 30) {
		$params{photoedit} = $self->photo_edit(
			photo => $obj,
			display => 'none',
			description => $obj->description(),
			status => $obj->status(),
		);
	}

	$params{analytics} = $self->analytics();

	return %params;
}

sub _photo_list_main {
	my $self = shift;
	my $obj = shift;

	my %params;

	my @navlink;
	if(my $title = $obj->title()) {
		$params{title} = ": $title";
		$params{description} = "$title.";
		$params{phototitle} = $title;
	}
	if(my $subtitle = $obj->subtitle()) {
		$params{subtitle} = $subtitle;
	} else {
		$params{subtitle} = '&nbsp;';
	}

	# set human-readable navigation links
	$params{navlinks} = $self->navlinks(
		prev => $obj->prev(),
		index => $obj->index(),
		next => $obj->next(),
	);

	# set machine-readable navigation links
	if(my $prev = $obj->prev()) {
		push @navlink, $self->navlink(
			type => 'prev',
			url => $prev->url(),
			title => $prev->title(),
		);
	}
	if(my $next = $obj->next()) {
		push @navlink, $self->navlink(
			type => 'next',
			url => $next->url(),
			title => $next->title(),
		);
	}
	if(my $index = $obj->index()) {
		push @navlink, $self->navlink(
			type => 'parent',
			url => $index->url(),
			title => $index->title(),
		);
	}
	$params{navlink} = join('', @navlink);

	$params{screencss} = $self->screencss();

	$params{content} = $obj->html();

	$params{analytics} = $self->analytics();

	return %params;
}

sub _photo_edit {
	my $self = shift;
	my %params = @_;

	# html-encode the description
	$params{description} =~ s/&/&amp;/g;
	$params{description} =~ s/"/&quot;/g;
	$params{description} =~ s/>/&gt;/g;
	$params{description} =~ s/</&lt;/g;

	$params{id} = $params{photo}->id();
	$params{round} = $params{photo}->round();
	$params{number} = $params{photo}->number();

	my $status = $params{status};
	if(!defined($status) || $status == 100) {
		$status = 0;
	}
	$params{status} =
		qq'<select name="status">\n' .
		join('', map { qq'<option value="$_"' . ($status == $_ ? " selected" : "") . qq'>$Jaeger::Changelog::Status{$_}</option>\n' } sort { $a <=> $b } keys %Jaeger::Changelog::Status) .
		qq'</select>\n';

	# Show all the available photo timezones
	my @timezones = Jaeger::Timezone->Select();
	$params{phototimezone} = 
		qq'<select name="phototimezone">\n' .
		join('', map { qq'<option value="' . $_->id() . qq'"' .
		($params{photo}->timezone_id() == $_->id() ? " selected" : "") .
		qq'>' . $_->name() . qq'</option>\n' } @timezones) .
		qq'</select>\n';

	# TODO Show all the available camera timezones
	#$params{cameratimezones} = ;

	# Show all the available photo sets
#<input type="checkbox" name="collections" value="11" checked>Dawn of the Julian Era</input><br/>
	my @this_photo_sets = @{$params{photo}->sets()};
	$params{collections} = join('',
		map { qq'<input type="checkbox" name="sets" value="' .
			$_->id() . qq'" checked>' . $_->name() . 
			qq'</input><br/>\n'}
		@this_photo_sets);
	my @all_sets = Jaeger::Photo::Set->Select();
	$params{collections} .= join('',
		map { qq'<input type="checkbox" name="sets" value="' .
			$_->id() . qq'">' . $_->name() . qq'</input><br/>\n'}
		@all_sets);

	return %params;
}

sub analytics {
	my $self = shift;

	# Do not include analytics in any pre-production environment (in
	# particular, alpha.festing.org and beta.festing.org).
	
	if($Jaeger::Base::BaseURL !~ /jaeger\.festing\.org/) {
		return "";
	}

	# Do not include analytics tracking if the logged-in user is Jaeger, to
	# avoid poluting the analytics data.
	my $user = Jaeger::User->Login();

	if($user && $user->status() >= 30) {
		return "";
	}

	return $self->_lookfeel('analytics');
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
		push @link, '&lt; <a href="' . $params{prev}->url() .
			'">Previous: ' . $params{prev}->title() . '</a>';
	} else {
		push @link, '&lt; Previous';
	}

	if(ref $params{index}) {
		push @link, ' [ <a href="' . $params{index}->url() . '">' .
			$params{index}->title() . '</a> ] ';
	} else {
		push @link, ' [ Index ] ';
	}

	if(ref $params{next}) {
		push @link, '<a href="' . $params{next}->url() . '">Next: ' .
			$params{next}->title() . '</a> &gt;';
	} else {
		push @link, 'Next &gt;';
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

=for later
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
=cut

	# Assemble a list of recent visitors
	my $where = "last_visit > now() + '-1h' and status > 0 order by last_visit desc";
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

	$params{business} = $params{business} ? "Yes" : "No";

	if($params{comment}) {
		$params{comment} =
			$self->flight_comment(comment => $params{comment});
	}

	if($params{distance} > 9999) {
		$params{distance} =~ s/(\d\d\d)$/,$1/;
	}

	return %params;
}

sub _flight_total {
	my $self = shift;

	my %params = @_;

	if($params{distance} > 9999) {
		$params{distance} =~ s/(\d\d\d)$/,$1/;
	}

	return %params;
}

sub _photo {
	my $self = shift;

	my %params = @_;

	my $user = Jaeger::User->Login();

	if($user && $user->status() >= 30) {
		$params{add_to_slideshow} = $self->add_to_slideshow(
			photo_id => $params{id}
		);
	}

	if(defined($params{longitude}) && defined($params{latitude})) {
		$params{location} = $self->photo_coordinates(
			longitude => $params{longitude},
			latitude => $params{latitude},
		);
	}

	return %params;
}

sub _photo_rss {
	my $self = shift;

	my %params = @_;

	if(defined($params{longitude}) && defined($params{latitude})) {
		$params{location} = $self->photo_coordinates(
			longitude => $params{longitude},
			latitude => $params{latitude},
		);
	}

	return %params;
}

sub _photo_coordinates {
	my $self = shift;

	my %params = @_;

	my $lat_dir = '';
	if($params{latitude} > 0) {
		$lat_dir = 'N';
	}
	if($params{latitude} < 0) {
		$lat_dir = 'S';
	}
	$params{lat_dsp} = sprintf "%s%d&deg;%6.3f",
		$lat_dir, int(abs($params{latitude})),
		POSIX::fmod(abs($params{latitude}) * 60, 60);

	my $lon_dir = '';
	if($params{longitude} > 0) {
		$lon_dir = 'E';
	}
	if($params{longitude} < 0) {
		$lon_dir = 'W';
	}
	$params{lon_dsp} = sprintf "%s%d&deg;%6.3f",
		$lon_dir, int(abs($params{longitude})),
		POSIX::fmod(abs($params{longitude}) * 60, 60);

	return %params;
}

sub _photo_list {
	my $self = shift;

	my %params = @_;

	$params{description} =~ s/&/&amp;/g;
	$params{description} =~ s/"/&quot;/g;
	$params{description} =~ s/</&lt;/g;
	$params{description} =~ s/>/&gt;/g;

	if(defined($params{longitude}) && defined($params{latitude})) {
		$params{location} = $self->photo_coordinates(
			longitude => $params{longitude},
			latitude => $params{latitude},
		);
	}

	return %params;
}

sub _add_to_slideshow {
	my $self = shift;

	my %params = @_;

	my @slideshows = sort {$a->id() <=> $b->id()}
		Jaeger::Slideshow->Select();

	$params{slideshow} = join('', map {'<option value="' . $_->id() . '">' . $_->{title} . "</option>\n"} @slideshows);

	return %params;
}

1;
