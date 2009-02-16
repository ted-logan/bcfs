#!/usr/bin/perl

#
# $Id: rss.cgi,v 1.4 2005-12-17 04:20:23 jaeger Exp $
#

# rss.cgi: Gives a RSS 0.91 content syndication feed

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::User;

print "content-type: text/xml\n\n";

print "<rss version=\"0.91\">\n";
print "\t<channel>\n";
print "\t\t<title>jaegerfesting</title>\n";
print "\t\t<link>http://jaeger.festing.org/changelog/</link>\n";
print "\t\t<description>Random content from a hacker in Louisville, Colorado. (That's pronounced \"lewis-ville\", in case you were wondering.)</description>\n";
print "\t\t<language>en-us</language>\n";

my $status = 0;

if($ENV{QUERY_STRING}) {
	my $user = Jaeger::User->Select(cookie => $ENV{QUERY_STRING});
	if($user) {
		$status = $user->status();
	}
}

# grab recent changelogs and print them out here
my @changelogs = Jaeger::Changelog->Select("status <= $status order by time_begin desc limit 10");
foreach my $changelog (@changelogs) {
	print "\t\t<item>\n";
	print "\t\t\t<title>", $changelog->title(), "</title>\n";
	print "\t\t\t<link>", $changelog->url(), "</link>\n";
	print "\t\t</item>\n";
}

print "\t</channel>\n";
print "</rss>\n";
