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

use File::Basename;
use LWP::UserAgent;

my $baseurl;

# Look for the file ".probecfg" in the running directory for the script, which
# (if it exists) has the base url for this site.

my $dirname = dirname(__FILE__);

if(open(PROBECFG, "$dirname/.probecfg")) {
	$baseurl = <PROBECFG>;
	chomp $baseurl;
	close PROBECFG;
} else {
	$baseurl = "https://jaeger.festing.org";
}

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
		# Post a reply to a changelog
		uri => "/changelog/1807.html/reply",
		success => 1,
		expect => "Password",
	},
	{
		# Changelog only visible to logged-in users
		uri => '/changelog/1768.html',
		success => 1,
		expect => "Password",
		exclude => "Geordi LaForge",
	},
	{
		# Query params at end of url
		uri => "/changelog/1819.html?utm_source=probe",
		success => 1,
		expect => "Image embed test",
	},
	{
		# Typo in url ending in "
		uri => "/changelog/1629.html\"",
		success => 1,
		expect => "2015 Hugo Awards",
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
		exclude => "anxiety",
	},
	{
		# Missing tag
		uri => "/changelog/tag/worlcon-76",
		success => 0,
		expect => "Not found",
		exclude => "worlcon-76",
	},
	{
		# Valid tag, but no entries visible to the default user
		uri => "/changelog/tag/anxiety",
		success => 0,
		expect => "Not found",
	},
	{
		uri => "/changelog/series/4",
		success => 1,
		expect => "My First Long-Haul Flight",
	},
	{
		uri => "/changelog/99999.html",
		success => 0,
		expect => "Not found",
		exclude => "/changelog//",
	},
	{
		uri => "/changelog/comment/99999.html",
		success => 0,
		expect => "Not found",
		exclude => "/changelog//",
	},
	{
		uri => "/changelog/9999/",
		success => 0,
		expect => "Not found",
		exclude => "/changelog//",
	},
	{
		uri => "/changelog/series/9999",
		success => 0,
		expect => "Not found",
		exclude => "/changelog//",
	},
	{
		uri => "/changelog/bogus",
		success => 0,
		expect => "Not found",
		exclude => "/changelog//",
	},

	# Comments
	{
		uri => "/changelog/comment/185.html",
		success => 1,
		expect => "Sibblings",
	},
	{
		uri => "/changelog/comment/185.html/reply",
		success => 1,
		expect => "Password",
	},
	{
		uri => "/changelog/comment/846.html",
		success => 1,
		expect => "Password",
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
		expect => "Password",
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

my $success = 0;
my $failure = 0;

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
				$response->status_line();
		} else {
			$result = 1;
		}
	} else {
		if($response->is_success()) {
			$result = 0;
			$reason = "expected failure, got success";
		} else {
			$result = 1;
		}
	}

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

	if($result) {
		print "PASS\n";
		$success++;
	} else {
		print "FAIL ($reason)\n";
		$failure++;
	}
}

print "\n";
print $success, " total successful probes\n";
if($failure) {
	print $failure, " total failing probe", ($failure == 1 ? '' : 's'),
		"\n";
	exit 1;
}
