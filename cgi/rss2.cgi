#!/usr/bin/perl

# rss2.cgi: Gives a RSS 2.0 content syndication feed

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::User;

use POSIX qw(strftime);

print "content-type: text/xml\n\n";

print "<?xml version=\"1.0\"?>\n";
print "<rss version=\"2.0\">\n";
print "\t<channel>\n";
print "\t\t<title>jaegerfesting</title>\n";
print "\t\t<link>http://jaeger.festing.org/changelog/</link>\n";
print "\t\t<description>Random content from a hacker in Longmont, Colorado. I still claim Boulder as my home.</description>\n";
print "\t\t<copyright>Copyright 1999-2009 Theodore Logan</copyright>\n";
print "\t\t<language>en-us</language>\n";
print "\t\t<docs>http://blogs.law.harvard.edu/tech/rss</docs>\n";

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
	print "\t\t\t<guid isPermaLink=\"true\">", $changelog->url(),
		"</guid>\n";
	print "\t\t\t<pubDate>", $changelog->pubDate(), "</pubDate>\n";
	if($changelog->status() == 0) {
		print "\t\t\t<description><![CDATA[", $changelog->content(), "]]></description>\n";
	}
	print "\t\t</item>\n";
}

print "\t</channel>\n";
print "</rss>\n";
