#!/usr/bin/perl

# Attempts to geotag photos

use strict;

use lib '/home/jaeger/src/bcfs/lib';
use Jaeger::GPS;
use Jaeger::Photo;
use Jaeger::Photo::List::Date;

my $list = new Jaeger::Photo::List::Date('2006-08-19');
foreach my $photo (@{$list->photos()}) {
	next if defined($photo->longitude()) && defined($photo->latitude());

	# Try to locate the track points before and after this photo
	my $before = Jaeger::GPS->Select(
		"date <= $photo->{date} order by date desc limit 1"
	);
	my @after = Jaeger::GPS->Select(
		"date >= $photo->{date} order by date asc limit 2"
	);

	# If the before and after points are equal, use the second after point
	if($before->date() == $after[0]->date()) {
		shift @after;
	}
	my $after = $after[0];

	# Don't geotag if the points are more than 5 km apart, or more than
	# 5 minutes apart, or are exactly the same.
	next if $before == $after;
	next if ($after->date() - $before->date()) > 300;
	next if ($before - $after) > 5;

	# Perform a linear regression between the two points
	my $delta_t = ($after->date() - $before->date());
	my $factor = $photo->{date} - $before->date();

	my $latitude = $before->latitude() +
		($after->latitude() - $before->latitude()) * $factor / $delta_t;
	my $longitude = $before->longitude() +
		($after->longitude() - $before->longitude()) *
			$factor / $delta_t;

	my $point = new Jaeger::GPS;
	$point->{date} = $photo->{date};
	$point->{latitude} = $latitude;
	$point->{longitude} = $longitude;

	print "$photo->{round}/$photo->{number}: $photo->{description}\n";
	print "\tBefore:\t$before\n";
	print "\tDate:\t$point\n";
	print "\tAfter:\t$after\n";
	print "\n";

	$photo->{latitude} = $latitude;
	$photo->{longitude} = $longitude;
	$photo->update();
}
