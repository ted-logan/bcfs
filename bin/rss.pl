#!/usr/bin/perl

#
# $Id: rss.pl,v 1.1 2004-05-07 02:43:16 jaeger Exp $
#

#
# Consult websites I deem worthy to have boxes on my site and insert the
# headlines into boxes
#
# Ted Logan
# 06 May 2004
#

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Lookfeel;

use XML::RSS;
use LWP::UserAgent;

my @links = qw(http://kiesa.festing.org/journal/xml-rss.php http://bitscape.org/lounge.rss);

my $lf = new Jaeger::Lookfeel;

my @html;

foreach my $link (@links) {
	push @html, parse_url($link);
}

my $sql = "update lookfeel set value = " . $lf->{dbh}->quote(join('', @html)) .
	", timestamp = now() where label = 'rss_links'";
$lf->{dbh}->do($sql);

exit;

# Fetches the given url, parses its rss, and returns a properly-formatted
# box for later inclusion on my site
sub parse_url {
	my $url = shift;

	# Grab the rss from the site
	my $ua = new LWP::UserAgent;
	my $response = $ua->get($url);

	my $rss = new XML::RSS;
	$rss->parse($response->content());

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
