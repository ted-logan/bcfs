#!/usr/bin/perl

#
# $Id: changelog.pl,v 1.4 2002-09-04 15:59:25 jaeger Exp $
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
my $id;
GetOptions(
	'date=s' => \$time_begin,
	'time_end=s' => \$time_end,
	"title=s" => \$title,
	"id=i" => \$id
);

my $tempfile = shift;

my $changelog;
if($id) {
	$changelog = new Jaeger::Changelog($id);
	unless($changelog) {
		die "Changelog with id = $id doesn't exist\n";
	}
	print "Selecting changelog id = $id (", $changelog->title(), ")\n";

} else {
	$changelog = new Jaeger::Changelog();

	$time_begin = timestamp($time_begin);
	$time_end = timestamp($time_end);

	if($time_begin) {
		$changelog->time_begin($time_begin);
	}
	if($time_end) {
		$changelog->time_end($time_end);
	}

	unless($title) {
		print "New Changelog Entry\n";
		print "Date: $time_begin\n";
		print "Title: ";
		$title = <>;
		chomp $title;
	}

	$changelog->title($title);
}

$changelog->edit($tempfile);

sub timestamp {
	my $time = shift;

	return scalar localtime($time ?
			`date --date="$time" +"%s"` :
			time);
}
