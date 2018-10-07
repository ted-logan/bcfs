#!/usr/bin/perl

# Stand-alone prober testing various public URLs (and URLs only exposed to
# various tiers of logged-in users), and various error conditions. This is used
# as an acceptance test suite, and as a prober to confirm that the site
# continues to work.
#
# Note that this relies on finding specific text after fetching various URLs,
# and that this relies on the state of the database, so it's possible that the
# tests could fail if the website content changes. I don't consider this to be
# a major problem, though.

use strict;

use LWP::UserAgent;

my $baseurl = "https://jaeger.festing.org";

my @tests = (
	{
		uri => "/",
		success => 1,
		expect => "/changelog/20\\d\\d/",
	},
	{
		uri => "/changelog",
		success => 1,
		expect => "/changelog/20\\d\\d/",
	},
	{
		uri => "/changelog/",
		success => 1,
		expect => "/changelog/20\\d\\d/",
	},
	{
		# Regular, public changelog
		uri => "/changelog/1807.html",
		success => 1,
		expect => "Tomales Bay",
	},
	{
		# Changelog only visible to logged-in users
		uri => '/changelog/1768.html',
		success => 1,
		expect => "Log In",
		exclude => "Geordi LaForge",
	},
	{
		uri => "/changelog/2018/",
		success => 1,
		expect => "Hawaiian Volcano Week",
		exclude => "Get Kuna",
	},
	{
		uri => "/changelog/tag/rocky-mountain-national-park",
		success => 1,
		expect => "Chiefs Head Reprise",
	},
	{
		uri => "/changelog/tag",
		success => 1,
		expect => "california",
	},
	{
		uri => "/changelog/tag/",
		success => 1,
		expect => "washington",
	},
	{
		uri => "/changelog/series/4",
		success => 1,
		expect => "My First Long-Haul Flight",
	},

	# Comments
	{
		uri => "/changelog/comment/185.html",
		success => 1,
		expect => "Sibblings",
	},
	{
		uri => "/changelog/comment/846.html",
		success => 1,
		expect => "Log In",
		exclude => "Congrats",
	},

	# Photos
	{
		uri => "/photo.cgi",
		success => 1,
		expect => "Recent photos",
	},
	{
		uri => "/photo.cgi?round=516&number=23",
		success => 1,
		expect => "Spire at the Marin County Civic Center",
	},
	{
		# Elite users only photo
		uri => "/photo.cgi?round=519&number=31",
		success => 1,
		expect => "Log In",
		exclude => "Shanghai bottle opener",
	},
	{
		uri => "/photo.cgi?round=516",
		success => 1,
		expect => "site model of the Marin County Civic Center",
	},
	{
		uri => "/photo.cgi?date=2018-07-15",
		success => 1,
		expect => "Kayaks launch from Tomales Bay",
		exclude => "Shanghai bottle opener",
	},
	{
		uri => "/photo.cgi?set=19",
		success => 1,
		expect => "Jaeger with Paddington Bear at Paddington Station",
	},
	{
		uri => "/photo.cgi?year=2018",
		success => 1,
		expect => "August 2018",
	},
);

my $ua = new LWP::UserAgent;

foreach my $test (@tests) {
	my $url = $baseurl . $test->{uri};

	print "$url  ";

	my $request = HTTP::Request->new(GET => $url);
	my $response = $ua->request($request);

	my $result;
	my $reason;

	if($test->{success}) {
		if(!$response->is_success()) {
			$result = 0;
			$reason = "expected success, got " .
				$result->status_line();
		} else {
			$result = 1;
			if($test->{expect} &&
				$response->content() !~ /$test->{expect}/) {
				$result = 0;
				$reason = "expected pattern /" .
					$test->{expect} . "/ not found";
			}
			if($test->{exclude} &&
				$response->content() =~ /$test->{exclude}/) {
				$result = 0;
				$reason = "excluded pattern /" .
					$test->{exclude} . "/ found";
			}
		}
	} else {
		if($response->is_success()) {
			$result = 0;
			$reason = "expected failure, got success";
		} else {
			$result = 1;
		}
	}

	if($result) {
		print "PASS\n";
	} else {
		print "FAIL ($reason)\n";
	}
}
