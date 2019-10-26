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
use Term::ANSIColor;

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
		redirect => "/changelog/2018/07/15/tomales-bay",
		success => 1,
		expect => "Tomales Bay",
	},
	{
		# Regular changelog with human-readable url
		uri => "/changelog/2019/07/25/victoria-clipper",
		success => 1,
		expect => "/changelog/2019/07/25/victoria-clipper/reply",
	},
	{
		# Very old, pre-2002 url scheme. 
		# As of August 2019, there are a few hits per day, virtually
		# all of which appear to be crawlers. The perverse part is that
		# these old changelogs are restricted-access, so they're not
		# really getting what they expect.
		uri => "/changelog.cgi?id=1811",
		redirect => "/changelog/2018/11/13/wallingford",
		success => 1,
		expect => "Wallingford",
	},
	{
		# The same, pre-2002 url scheme.
		uri => "/changelog.cgi?browse=2019",
		redirect => "/changelog/2019/",
		success => 1,
		expect => "Haleakala",
	},
	{
		# Post a reply to a changelog
		uri => "/changelog/1807.html/reply",
		success => 1,
		expect => "Password",
	},
	{
		# Post a reply to a changelog, human-readable url
		uri => "/changelog/2019/07/25/victoria-clipper/reply",
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
		# Changelog only visible to logged-in users, human-readable url
		uri => '/changelog/2019/03/24/rain',
		success => 1,
		expect => "Password",
		exclude => "citation needed",
	},
	{
		# Query params at end of url
		uri => "/changelog/1819.html?utm_source=probe",
		#redirect => "/changelog/2019/01/01/image-embed-test?utm_source=probe",
		redirect => "/changelog/2019/01/01/image-embed-test",
		success => 1,
		expect => "Image embed test",
	},
	{
		# Query params at end of url, human-readable url
		uri => "/changelog/2019/07/04/fireworks-at-the-gasworks?utm_source=probe",
		success => 1,
		expect => "Fireworks at the Gasworks",
	},
	{
		# Typo in url ending in "
		uri => "/changelog/1629.html\"",
		redirect => "/changelog/2015/09/30/2015-hugo-awards",
		success => 1,
		expect => "2015 Hugo Awards",
	},
	{
		# Confirm that inline photos are inlined
		uri => "/changelog/2019/09/02/hail-columbia",
		success => 1,
		expect => "/photo/2019/09/02/apollo-f1-rocket-motor",
	},
	{
		uri => "/changelog/2003/",
		success => 1,
		expect => '<a href="https://.*.festing.org/changelog/2004/">2004</a>',
		exclude => '<a href="https://.*.festing.org/changelog/2002/">2002</a>',
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
	# Page was moved via redirect
	{
		uri => "/changelog/2019/01/23/new-years-2019",
		redirect => "/changelog/2019/01/01/new-years-2019",
		success => 1,
		expect => "an easy walk from my house in Wallingford",
	},
	{
		uri => "/changelog/2019/01/01/new-years-2019",
		success => 1,
		expect => "an easy walk from my house in Wallingford",
	},
	# Page was moved via redirect
	{
		uri => "/changelog/2019/02/27/visiting-the-sun",
		redirect => "/changelog/2019/02/17/visiting-the-sun",
		success => 1,
		expect => "I need to go visit the sun in the winter",
	},
	{
		uri => "/changelog/2019/02/17/visiting-the-sun",
		success => 1,
		expect => "I need to go visit the sun in the winter",
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
		redirect => "/photo/",
		success => 1,
		expect => "Recent photos",
	},
	{
		uri => "/photo",
		redirect => "/photo/",
		success => 1,
		expect => "/photo/",
	},
	{
		uri => "/photo/",
		success => 1,
		expect => "Recent photos",
	},
	{
		uri => "/photo/bogus",
		success => 0,
		expect => "Not found",
	},
	{
		uri => "/photo.cgi?round=516&number=23",
		redirect => "/photo/2018/07/06/spire-at-the-marin-county-civic-center",
		success => 1,
		expect => "Spire at the Marin County Civic Center",
	},
	{
		uri => "/photo.cgi?round=300&number=18",
		redirect => "/photo/2013/12/10/jaegers-office-view-with-snow",
		success => 1,
		expect => "/digitalpics/300/1600x1200/18.jpg",
	},
	{
		uri => "/photo/2019/06/29/walking-along-english-bay-in-vancouver-2",
		success => 1,
		expect => "17:15:19 PDT Saturday 29 June 2019",
	},
	{
		uri => "/photo/2019/09/14/kayaks-paddle-past-ben-ure-island",
		redirect => "/photo/2019/09/14/kayaks-paddle-towards-yokeko-point",
		success => 1,
		expect => "Kayaks paddle towards Yokeko Point",
	},
	{
		# Photo was hidden
		uri => "/photo.cgi?round=097&number=13",
		success => 0,
		expect => "Not found",
	},
	{
		# Photo not found (in an existing round)
		uri => "/photo.cgi?round=516&number=9999",
		success => 0,
		expect => "Not found",
	},
	{
		# Photo not found (in a bogus round)
		uri => "/photo.cgi?round=9999&number=9999",
		success => 0,
		expect => "Not found",
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
		# Round not found
		uri => "/photo.cgi?round=9999",
		success => 0,
		expect => "Not found",
	},
	{
		uri => "/photo.cgi?date=2018-07-15",
		redirect => "/photo/2018/07/15/",
		success => 1,
		expect => "Kayaks launch from Tomales Bay",
		exclude => "Shanghai bottle opener",
	},
	{
		uri => "/photo/2019/08/21/",
		success => 1,
		expect => "Rain on Hanbury Lane",
		exclude => "Pint of Guinness at a pub in Dublin",
	},
	{
		uri => "/photo/2019/09/02",
		success => 1,
		expect => "Columbia",
	},
	{
		uri => "/photo.cgi?set=19",
		success => 1,
		expect => "Jaeger with Paddington Bear at Paddington Station",
	},
	{
		uri => "/photo.cgi?year=2018",
		redirect => "/photo/2018/",
		success => 1,
		expect => "August 2018",
	},
	{
		uri => "/photo/2018",
		redirect => "/photo/2018/",
		success => 1,
		expect => "August 2018",
	},
	{
		uri => "/photo/2017/",
		redirect => "/photo/2017/",
		success => 1,
		expect => "/photo/2016/",
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

	my $actual_uri = $response->base()->path_query();
	my $redirect_ok = "";
	if($test->{redirect}) {
		if($actual_uri ne $test->{redirect}) {
			$reason = "expected redirect to $test->{redirect}, " .
				"instead reached $actual_uri";
			$result = 0;
		} else {
			$redirect_ok = " ok";
		}
	}
	if($actual_uri ne $test->{uri}) {
		print color('white', 'italic'),
			"(redirect$redirect_ok: ", $actual_uri, ")  ",
			color('reset');
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
		print color('green'), "PASS", color('reset'), "\n";
		$success++;
	} else {
		print color('red'), "FAIL", color('reset'), " ($reason)\n";
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
