package		Jaeger::Lookfeel;

#
# $Id: Lookfeel.pm,v 1.3 2002-07-11 15:56:04 jaeger Exp $
#

#	Copyright (c) 1999-2002 Ted Logan (jaeger@festing.org)

# 06 May 1999 Ted Logan <jaeger@festing.org>
# modified 07 June 1999 for x13
# modified 29 August 1999 to use x13::Base
# modified 28 May 2000 for jaegerfesting
# updated 18 May 2002

use strict;

use Jaeger::Base;

use Fortune;

@Jaeger::Lookfeel::ISA = qw(Jaeger::Base);

@Jaeger::Lookfeel::KeepParams = qw(what id label year);

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

	# count down to graduation: 09 June 2002
	$params{graddaysleft} = int((1023606000 - time) / 86400);

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

1;
