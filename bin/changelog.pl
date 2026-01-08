#!/usr/bin/perl

#
# $Id: changelog.pl,v 1.9 2004-06-26 19:53:56 jaeger Exp $
#

# 28 May 2000
# Ted Logan

use strict;
use Getopt::Long;

use lib::relative '../lib';

use Jaeger::Changelog;
use Jaeger::User;

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

my $changelog;
if(@ARGV) {
	my $arg = $ARGV[0];
	# One command-line argument is provided. If it's a url, edit that
	# changelog. If it's a file, import it.
	if($arg =~ /^http/) {
		$arg =~ s(^https?://.*?/)(/);
		my $user = Jaeger::User->Select(login => 'jaeger');
		do {
			$changelog = Jaeger::Changelog::Urimap($arg, $user);
			if(ref($changelog) eq 'Jaeger::Redirect') {
				$arg = $changelog->{url};
				print "Got redirect to $arg\n";
			}
		} while(ref($changelog) eq 'Jaeger::Redirect');
		if($changelog) {
			print "Found changelog with uri $arg\n";
		} else {
			die "Unable to find changelog with uri $arg\n";
		}

	} elsif(-f $arg) {
		$changelog = new Jaeger::Changelog();

		$changelog->{status} = 0;

		$changelog->import_file($arg);
	} else {
		die "Unrecogonized argument '$arg'\n";
	}
} elsif($id) {
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

$changelog->edit();
