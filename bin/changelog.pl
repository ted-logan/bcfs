#!/usr/bin/perl

#
# $Id: changelog.pl,v 1.7 2003-04-25 19:01:00 jaeger Exp $
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
my $help;
GetOptions(
	'date=s' => \$time_begin,
	'time_end=s' => \$time_end,
	"title=s" => \$title,
	"id=i" => \$id,
	"help" => \$help,
);

if($help) {
	print 'changelog creator $Revision: 1.7 $', "\n";
	print "Command-line options:\n";
	print "\t--date=date     Specify the beginning date\n";
	print "\t                Default: time at beginning of edit\n";
	print "\t--time_end=date Specify the ending date\n";
	print "\t                Default: time at end of edit\n";
	print "\t--title=title   Specify the title\n";
	print "\t                Default: ask\n";
	print "\t--id=id         Edit an existing changelog, by id\n";
	print "\t--help          Show this help screen\n";
	exit;
}

my $tempfile = shift;

my $changelog;
if($id) {
	$changelog = Jaeger::Changelog->new_id($id);
	unless($changelog) {
		die "Changelog with id = $id doesn't exist\n";
	}
	print "Selecting changelog id = $id (", $changelog->title(), ")\n";

} else {
	$changelog = new Jaeger::Changelog();

	$time_begin = timestamp($time_begin);
	if($time_end) {
		$time_end = timestamp($time_end);
	}

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

	$changelog->{title} = $title;
}

$changelog->edit($tempfile);

sub timestamp {
	my $time = shift;

	return scalar localtime($time ?
			`date --date="$time" +"%s"` :
			time);
}
