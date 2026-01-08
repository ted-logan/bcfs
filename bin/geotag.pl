#!/usr/bin/perl

# Attempts to geotag photos

use strict;

use lib::relative '../lib';

use Jaeger::GPS;
use Jaeger::Photo;

# Determine the first and last track point in the database
my $first_point = Jaeger::GPS->Select("1=1 order by date asc limit 1");
my $last_point = Jaeger::GPS->Select("1=1 order by date desc limit 1");

print "First point: $first_point\n";
print "Last point:  $last_point\n";

my @photos = Jaeger::Photo->Select("date >= $first_point->{date} and date <= $last_point->{date} and (longitude is null or latitude is null)");

foreach my $photo (@photos) {
	next if defined($photo->longitude()) && defined($photo->latitude());

	my $point = $photo->geotag();
	next unless defined $point;

	print "$photo->{round}/$photo->{number}: $photo->{description}\n";
	print "\tDate:\t$point\n";
	print "\n";

	$photo->update();
}
