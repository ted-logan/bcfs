#!/usr/bin/perl

#
# $Id: rss.pl,v 1.5 2005-05-14 00:04:44 jaeger Exp $
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
use Jaeger::UserBox;

use XML::RSS;
use LWP::UserAgent;

# Kiesa's page used to be http://kiesa.diaryland.com/index.rss
# But that doesn't work. 13 May 2005
my @links = qw();

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

$lf->{dbh}->do("delete from lookfeel where label like 'rss_links%'");

my $sql = "insert into lookfeel values ('rss_links', now(), " .
	$lf->{dbh}->quote(join('', @html)) . ")";
$lf->{dbh}->do($sql);

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

	my $sql = "insert into lookfeel values ('rss_links_$user->{login}', " .
		"now(), " . $lf->{dbh}->quote($user_boxes{$uid}) . ")";

	$lf->{dbh}->do($sql);
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

	# Clean up broken XML for Diaryland, et al
	my $content = $response->content();
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
