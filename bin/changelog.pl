#!/usr/bin/perl

#
# $Id: changelog.pl,v 1.1 2002-05-19 22:51:41 jaeger Exp $
#

# 28 May 2000
# Ted Logan

use strict;
use POSIX qw(floor);
use Getopt::Long;

use lib '/home/jaeger/programming/webpage/lib';
use Jaeger::Changelog;

my $seconds; # seconds from the epoch
my $timestamp; # timestamp entry
my $date; # temporary varible
my $title;
GetOptions('date=s', \$date, "title=s", \$title);
if($date) {
	$seconds = `date --date="$date" +"%s"`;
} else {
	$seconds = time;
}

my $tempfile = shift;

$timestamp = scalar localtime $seconds;

my $changelog = new Jaeger::Changelog();
$changelog->time_begin($timestamp);

unless($title) {
	print "New Changelog Entry\n";
	print "Date: $timestamp\n";
	print "Title: ";
	$title = <>;
	chomp $title;
}
$changelog->title($title);

unless($tempfile) {
	$tempfile = "/tmp/article-$$.html";
}

system qq(vi $tempfile "+set textwidth=72");
if(-s $tempfile) {
	# spellcheck it
	system "ispell $tempfile";

	open TF, $tempfile;
	undef $/;
	my $content = <TF>;

	print "Inserting changelog entry\n";
	$changelog->content($content);
	$changelog->insert();
} else {
	print "Aborting zero-length entry\n";
}
close TF;
unlink $tempfile;
