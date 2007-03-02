#!/usr/bin/perl

# $Id: import_track.pl,v 1.1 2007-03-02 04:14:32 jaeger Exp $
#
# Imports GPS track data into my database
#
# gpsbabel version: 1 March 2007

use strict;

use POSIX qw(strftime);
use Time::Local;
use XML::DOM;

use lib '/home/jaeger/src/bcfs/lib';
use Jaeger::GPS;

# Assume that the points are imported in chronological order
# Discard points that are not newer than the most recent import.
my $min_date = do {
	my $newest_point =
		Jaeger::GPS->Select("1=1 order by date desc limit 1");
	$newest_point ? $newest_point->date() : 0;
};

my $parser = new XML::DOM::Parser;

foreach my $file (@ARGV) {
	my $import_date = strftime("%Y-%m-%d %H:%M:%S %z",
		localtime((stat $file)[9]));

	print "$file: $import_date\n";
	if($min_date) {
		print "Ignoring points older than ",
			scalar(localtime $min_date), "\n";
	}

	my $imported = 0;

	my $doc = $parser->parsefile($file);

	my $nodes = $doc->getElementsByTagName("trkpt");
	for(my $i = 0; $i < $nodes->getLength(); $i++) {
		my $node = $nodes->item($i);

		my $point = new Jaeger::GPS;
		$point->{latitude} = $node->getAttributeNode("lat")->getValue();
		$point->{longitude} = $node->getAttributeNode("lon")->getValue();
		$point->{downloaded} = $import_date;

		if(my @n = $node->getElementsByTagName('ele')) {
			$point->{elevation} = $n[0]->getFirstChild()->getData();
		}

		if(my @n = $node->getElementsByTagName('time')) {
			my $date = $n[0]->getFirstChild()->getData();
			my @date = split /\D/, $date;
			$date[0] -= 1900;
			$date[1]--;

			$point->{date} = timegm(reverse @date);
		}

		print "$point\n";

		next unless $point->date() > $min_date;

		$point->update();
		$min_date = $point->date();
		$imported++;
	}

	$doc->dispose();

	close FILE;

	print "$file: $imported points imported\n";
}
