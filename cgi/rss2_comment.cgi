#!/usr/bin/perl

# rss2.cgi: Gives a RSS 2.0 content syndication feed

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::User;

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

	# Some RSS aggregators (*cough* Bloglines *cough*) have funny ideas
	# about what should be done with a "private" RSS feed. I carefully
	# restrict access to content to keep Google from finding out too much
	# about me, but I want to grant _some_ access through RSS. So here are
	# my content rules:
	#
	# (1) Publically-readable articles (status == 0) are shown in their
	#     entirety.
	# (2) Logged-in-user-only articles (status == 10) have their first
	#     paragraph shown, with a link to read the rest of the article on
	#     my website.
	# (3) More-secure articles (status > 10) are not shown at all; instead,
	#     a link is provided.
	my $content;
	if($changelog->status() == 0) {
		$content = $changelog->content();
	} elsif($changelog->status() == 10) {
		# Show only the first paragraph. Hope the first paragraph is
		# meaningful.
		$content = $changelog->content();
		$content =~ s/(^$).*//ms;
		$content .= "<p><i>Read more of this " .
			$Jaeger::Changelog::Status{$changelog->status()} .
			" entry: " . $changelog->link() . "</i></p>";
	} else {
		# Show only a link to read further.
		$content = "<p><i>Read more of this " .
			$Jaeger::Changelog::Status{$changelog->status()} .
			" entry: " . $changelog->link() . "</i></p>";
	}
	print "\t\t\t<description><![CDATA[", $content, "]]></description>\n";

	print "\t\t</item>\n";
}

print "\t</channel>\n";
print "</rss>\n";
