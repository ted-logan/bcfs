#!/usr/bin/perl

# rss.cgi: Gives a RSS 2.0 content syndication feed for entries and comments

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::Comment;
use Jaeger::User;

my $status = 0;

if($ENV{QUERY_STRING}) {
	my $user = Jaeger::User->Select(cookie => $ENV{QUERY_STRING});
	if($user) {
		$status = $user->status();
	}
}

my $feed;
my @entries;

if($0 =~ /comment/) {
	# This is a comment feed
	$feed->{title} = "jaegerfesting Comments";
	$feed->{description} = "Comments posted on jaeger.festing.org.";
	$feed->{noun} = "comment";

	@entries = Jaeger::Comment->Select(
		"status <= $status order by date desc limit 10"
	);
} else {
	# This is a changelog feed
	$feed->{title} = "jaegerfesting";
	$feed->{description} = "Random content from a hacker in Longmont, Colorado. I still claim Boulder as my home.";
	$feed->{noun} = "entry";

	@entries = Jaeger::Changelog->Select(
		"status <= $status order by time_end desc limit 10"
	);
}

print "content-type: text/xml\n\n";

print "<?xml version=\"1.0\"?>\n";
print "<rss version=\"2.0\">\n";
print "\t<channel>\n";
print "\t\t<title>", $feed->{title}, "</title>\n";
print "\t\t<link>http://jaeger.festing.org/changelog/</link>\n";
print "\t\t<description>$feed->{description}</description>\n";
print "\t\t<copyright>Copyright 1999-2010 Theodore Logan</copyright>\n";
print "\t\t<language>en-us</language>\n";
print "\t\t<docs>http://blogs.law.harvard.edu/tech/rss</docs>\n";

# grab recent entries or articles and print them out here
foreach my $entry (@entries) {
	print "\t\t<item>\n";
	print "\t\t\t<title>", $entry->title(), "</title>\n";
	if(ref($entry) =~ /^Jaeger::Comment/) {
		print "\t\t\t<author><![CDATA[", $entry->user()->name(),
			"]]></author>\n";
	}
	print "\t\t\t<link>", $entry->url(), "</link>\n";
	print "\t\t\t<guid isPermaLink=\"true\">", $entry->url(),
		"</guid>\n";
	print "\t\t\t<pubDate>", $entry->pubDate(), "</pubDate>\n";

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
	if($entry->status() == 0) {
		$content = $entry->content();
	} elsif($entry->status() == 10) {
		# Show only the first paragraph. Hope the first paragraph is
		# meaningful.
		$content = $entry->content();
		$content =~ s/(^\r?$)(.*)//ms;
		if($2) {
			$content .= "<p><i>Read more of this " .
				$Jaeger::Changelog::Status{$entry->status()} .
				" " . $feed->{noun} . ": " . $entry->link() .
				"</i></p>";
		}
	} else {
		# Show only a link to read further.
		$content .= "<p><i>Read this " .
			$Jaeger::Changelog::Status{$entry->status()} .
			" " . $feed->{noun} . ": " . $entry->link() .
			"</i></p>";
	}
	print "\t\t\t<description><![CDATA[", $content, "]]></description>\n";

	print "\t\t</item>\n";
}

print "\t</channel>\n";
print "</rss>\n";
