#!/usr/bin/perl

#
# $Id: rss.pl,v 1.6 2006-01-07 18:41:38 jaeger Exp $
#

#
# Consult websites I deem worthy to have boxes on my site and insert the
# headlines into boxes
#
# Ted Logan
# 06 May 2004
#

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Lookfeel;
use Jaeger::UserBox;

use Encode;
use XML::RSS;
use LWP::UserAgent;

my @links = qw(
	http://kiesa.festing.org/wordpress/feed/
	http://mega.festing.org/script/index.php?title=Special:Recentchanges&feed=rss
	http://www.willylogan.com/?feed=rss2
);

my $lf = new Jaeger::Lookfeel;

my @html;

# Update global rss boxes

foreach my $link (@links) {
	eval {
		push @html, parse_url($link);
	};
	if($@) {
		warn "Error reading $link: $@\n";
	}
}

Jaeger::Lookfeel->Update('rss_links', Encode::encode_utf8(join('', @html)));

# Update personal rss boxes

my %user_boxes;
foreach my $box (Jaeger::UserBox->Select('1=1 order by title')) {
	eval {
		$user_boxes{$box->{user_id}} .= parse_url($box->{url});
	};
	if($@) {
		warn "Error reading [$box->{id}] $box->{url}: $@\n";
	}
}

foreach my $uid (keys %user_boxes) {
	my $user = Jaeger::User->new_id($uid);

	Jaeger::Lookfeel->Update('rss_links_' . $user->{login},
		$user_boxes{$uid});
}

exit;

# Fetches the given url, parses its rss, and returns a properly-formatted
# box for later inclusion on my site
sub parse_url {
	my $url = shift;

	# Grab the rss from the site
	my $ua = new LWP::UserAgent;
	my $response = $ua->get($url);

	if(!$response->is_success()) {
		# Site didn't respond
		return undef;
	}

	my $content = Encode::decode_utf8($response->content());

	# Clean up broken XML for Diaryland, et al
	$content =~ s#<description>.*?</description>##g;

	my $rss = new XML::RSS;
	$rss->parse($content);

	my @links;

	my $i = 0;
	foreach my $item (@{$rss->{items}}) {
		last if ++$i > 10;

		push @links, $lf->link(
			url => $item->{link},
			title => $item->{title},
		);
	}

	return $lf->linkbox(
		url => $rss->{channel}->{link},
		title => $rss->{channel}->{title},
		links => join('', @links),
	);
}
