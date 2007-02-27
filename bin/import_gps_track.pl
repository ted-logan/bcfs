#!/usr/bin/perl

# $Id: import_gps_track.pl,v 1.1 2007-02-27 03:43:34 jaeger Exp $
#
# Imports GPS track data into my database
#
# 17 February 2007

use strict;

use POSIX qw(strftime);
use Time::Local;

use lib '/home/jaeger/src/bcfs/lib';
use Jaeger::GPS;

# Decode degree decimal-minute form (39°57.064') into decimal degrees
sub decode_ddm {
	my $coord = shift;

	my ($sign, $degree, $minute) = $coord =~ /(-?)(\d+)\D(\d+\.\d+)'/;

	return $sign . ($degree + $minute / 60);
}

# Assume that the points are imported in chronological order
# Discard points that are not newer than the most recent import.
my $min_date = do {
	my $newest_point =
		Jaeger::GPS->Select("1=1 order by date desc limit 1");
	$newest_point ? $newest_point->date() : 0;
};

foreach my $file (@ARGV) {
	my $import_date = strftime("%Y-%m-%d %H:%M:%S %z",
		localtime((stat $file)[9]));

	print "$file: $import_date\n";
	if($min_date) {
		print "Ignoring points older than ",
			scalar(localtime $min_date), "\n";
	}

	open FILE, $file
		or die "Can't open $file: $!\n";

	my $offset = 0;
	my $imported = 0;

	while(<FILE>) {
		if(/UTC Offset:\s*(\S+)/) {
			$offset = $1;
			next;
		}

		chomp;
		my @data = split;
		my $lat = decode_ddm($data[3]);
		my $lon = decode_ddm($data[4]);

		next unless $lat && $lon;

		my @date = split /[\/ :]/, "$data[1] $data[2]";
		$date[2] -= 1900;
		$date[0]--;

		my $date = timegm($date[5], $date[4], $date[3], $date[1],
			$date[0], $date[2]);
		$date -= $offset * 3600;

		next unless $date > $min_date;

		my $point = new Jaeger::GPS;

		$point->{latitude} = $lat;
		$point->{longitude} = $lon;
		$point->{date} = $date;
		$point->{downloaded} = $import_date;

		$point->update();

		$min_date = $date;
		$imported++;
	}

	close FILE;

	print "$file: $imported points imported\n";
}
