#!/usr/bin/perl

# $Id: import_track.pl,v 1.3 2007-05-23 01:09:22 jaeger Exp $
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
use Jaeger::Photo::List;
use Jaeger::Photo::List::Date;

# Assume that the points are imported in chronological order
# Discard points that are not newer than the most recent import.
my $min_date = do {
	my $newest_point =
		Jaeger::GPS->Select("1=1 order by date desc limit 1");
	$newest_point ? $newest_point->date() : 0;
};

my $parser = new XML::DOM::Parser;

my %new_dates;

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

		next unless $point->date() > $min_date;
		next unless $point->date() <= time;

		print "$point\n";

		$point->update();
		$min_date = $point->date();
		$imported++;

		$new_dates{strftime("%Y-%m-%d", localtime $point->date())}++;
	}

	$doc->dispose();

	close FILE;

	print "$file: $imported points imported\n";
}

# Try to geotag photos for the new dates provided
foreach my $date (sort keys %new_dates) {
	my $list = new Jaeger::Photo::List::Date($date);
	my $photos = $list->photos();
	next unless $photos;
	foreach my $photo (@$photos) {
		next if defined($photo->longitude()) &&
			defined($photo->latitude());
		my $point = $photo->geotag();
		if($point) {
			print "$photo->{round}/$photo->{number}: $photo->{description}\n";
			print "\t$point\n";
			$photo->update();
		}
	}
}
