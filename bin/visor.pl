#!/usr/bin/perl

#
# $Id: visor.pl,v 1.1 2003-01-20 19:41:36 jaeger Exp $
#

# Reads changelogs from my Visor and imports new ones

use strict;

use lib '/home/jaeger/programming/webpage/lib';
use Palm::Memo;
use Jaeger::Changelog;

my $pdb = new Palm::PDB;
$pdb->Load('/home/jaeger/visorbackup/MemoDB.pdb');

# figure out what the changelog caterogy is
my $changelog_cat = find_changelog_category($pdb);
if($changelog_cat == -1) {
	die "Unable to locate changelog category\n";
}

print "Changelog category is $changelog_cat\n";

open SD, "$ENV{HOME}/.visorupdate";
my $last_sync = <SD>;
chomp $last_sync;
close SD;

print "Last sync was ", scalar(localtime $last_sync), "\n";

foreach my $record (@{$pdb->{records}}) {
	if($record->{category} == $changelog_cat) {
		import_visor($last_sync, $record->{data});
	}
}

# update the start date
open SD, ">$ENV{HOME}/.visorupdate";
print SD time, "\n";
close SD;

# all done
exit;

sub find_changelog_category {
	my $pdb = shift;

	my @categories = @{$pdb->{appinfo}{categories}};

	for(my $cc = 0; $cc < @categories; $cc++) {
		return $cc if $categories[$cc]->{name} eq 'Changelog';
	}

	return -1;
}

sub import_visor {
	my $startdate = shift;

	my @lines = split /\n/, join('', @_);

	my $time_begin = parsetime(shift @lines);
	if($time_begin) {
		return if $time_begin < $startdate;
		print "Time begin = ", scalar(localtime($time_begin)), "\n";
		if($lines[1] =~ / 20$/) {
			$lines[1] .= '02';
		}
		my $time_end = parsetime(shift @lines);
		print "Time end   = ", scalar(localtime($time_end)), "\n";
		my $title = shift @lines;
		print "Title      = $title\n";

		# consume an empty line
		shift @lines;

		my $data = "<p>\n" . join("\n", @lines) . "</p>\n";
		$data =~ s/^$/<\/p>\n\n<p>/gm;
		$data =~ s/\047/'/g;

		my $changelog = new Jaeger::Changelog();

		$changelog->time_begin(scalar localtime $time_begin);
		$changelog->time_end(scalar localtime $time_end);
		$changelog->title($title);
		$changelog->content($data);

		$changelog->edit();
	}
}

sub parsetime {
	my $raw = shift;
	return `date --date="$raw" +%s 2>/dev/null`;
}
