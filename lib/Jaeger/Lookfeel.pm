package		Jaeger::Lookfeel;

#
# $Id: Lookfeel.pm,v 1.6 2002-11-02 17:16:45 jaeger Exp $
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

use Fortune;

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
			time_end => $params{time_end}
		);
	} elsif($params{time_begin}) {
		$params{timestamp} = $self->changelog_timebegin(
			time_begin => $params{time_begin}
		);
	}

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
	$params{navlinks} = $self->navlinks(
		prev => $obj[0]->prev(),
		index => $obj[0]->index(),
		next => $obj[0]->next(),
	);

	# get a quote
	my $fortune = new Fortune;
	$fortune->read('/home/jaeger/text/quotes/quotes');

	my $quote = $fortune->quote();
	$quote =~ s/$/<br>/mg;

	$params{quote} = "<tt>$quote</tt>";

	# populate the navigation links
	my @navbar;
	if((ref $obj[0]) eq 'Jaeger::Content') {
		push @navbar, $obj[0]->Navbar();
	} else {
		push @navbar, Jaeger::Content->Navbar();
	}

	if(ref $obj[0] eq 'Jaeger::Changelog') {
		push @navbar, $obj[0]->Navbar();
	} else {
		push @navbar, Jaeger::Changelog->Navbar();
	}
	push @navbar, Jaeger::Journal->Navbar();
	$params{navbar} = $self->links(linkbox => join('', @navbar));

	# populate content solutions data: links, chatterbox
	$params{links} = 'Coming soon: Content Solutions links';
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

	$params{indent} = '&nbsp;&nbsp;&nbsp;' x $params{level};

	if($params{current} eq $params{title}) {
		$params{title} = '<font color="#ffffff">' . $params{title} . '</font>';
	}

	if(ref $params{children}) {
		my @children;
		foreach my $child (@{$params{children}}) {
			push @children, $self->content_link(
				level => $params{level} + 1,
				current => $params{current},
				%$child
			);
		}
		$params{children} = join('', @children);
	}

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
	}

	return %params;
}

1;
