#!/usr/bin/perl

#
# $Id: changelog.pl,v 1.2 2002-06-03 01:48:19 jaeger Exp $
#

# 28 May 2000
# Ted Logan

use strict;
use POSIX qw(floor);
use Getopt::Long;

use lib '/home/jaeger/programming/webpage/lib';
use Jaeger::Changelog;

my ($time_begin, $time_end); # temporary varible
my $title;
GetOptions('date=s',\$time_begin, 'time_end=s',\$time_end, "title=s",\$title);

$time_begin = timestamp($time_begin);

my $tempfile = shift;

my $changelog = new Jaeger::Changelog();
$changelog->time_begin($time_begin);

unless($title) {
	print "New Changelog Entry\n";
	print "Date: $time_begin\n";
	print "Title: ";
	$title = <>;
	chomp $title;


$changelog->title($title);

unless($tempfile) {
	$tempfile = "/tmp/article-$$.html";
}

system qq(vi $tempfile "+set textwidth=72");
if(-s $tempfile) {
	$time_end = timestamp($time_end);

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

sub timestamp {
	my $time = shift;

	return scalar localtime($time ?
			`date --date="$time_begin" +"%s"` :
			time);
}
