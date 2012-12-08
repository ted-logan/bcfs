#!/usr/bin/perl

#
# $Id: changelog.pl,v 1.9 2004-06-26 19:53:56 jaeger Exp $
#

# 28 May 2000
# Ted Logan

use strict;
use POSIX qw(floor);
use Getopt::Long;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";
use Jaeger::Changelog;

my $id;
my $import;
my $help;
GetOptions(
	"id=i" => \$id,
	"import=s" => \$import,
	"help" => \$help,
);

if($help) {
	print 'changelog creator $Revision: 1.9 $', "\n";
	print "Command-line options:\n";
	print "\t--import FILE	 Read FILE as an offline changelog\n";
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

} elsif($import) {
	$changelog = new Jaeger::Changelog();

	$changelog->{status} = 0;

	$changelog->import_file($import);

} else {
	$changelog = new Jaeger::Changelog();

	$changelog->{status} = 0;

	$changelog->{time_begin} = scalar localtime time;
}

$changelog->edit($tempfile);
