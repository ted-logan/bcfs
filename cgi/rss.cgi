#!/usr/bin/perl

#
# $Id: rss.cgi,v 1.1 2003-08-10 20:24:26 jaeger Exp $
#

# rss.cgi: Gives a RSS 0.91 content syndication feed

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Changelog;

print "content-type: text/xml\n\n";

print "<rss version=\"0.91\">\n";
print "\t<channel>\n";
print "\t\t<title>jaegerfesting</title>\n";
print "\t\t<link>http://jaeger.festing.org/changelog/</link>\n";
print "\t\t<description>Random content from a hacker in Louisville, Colorado. (That's pronounced \"lewis-ville\", in case you were wondering.)</description>\n";
print "\t\t<language>en-us</language>\n";

# grab recent changelogs and print them out here
my @changelogs = Jaeger::Changelog->Select("1=1 order by time_begin desc limit 10");
foreach my $changelog (@changelogs) {
	print "\t\t<item>\n";
	print "\t\t\t<title>", $changelog->title(), "</title>\n";
	print "\t\t\t<link>http://jaeger.festing.org", $changelog->url(), "</link>\n";
	print "\t\t</item>\n";
}

print "\t</channel>\n";
print "</rss>\n";
