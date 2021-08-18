#!/usr/bin/perl

# thumbnail.cgi: Resizes a photo to the given size (without displaying it)
# This is intended to be used as an RPC to ensure that the photo exists

use strict;

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;

my $q = Jaeger::Base::Query();

my $round = $q->param('round');
my $number = $q->param('number');
my $size = $q->param('size');

if($round && $number && $size) {
	my $photo = Jaeger::Photo->Select(
		round => $round,
		number => $number
	);
	if(!$photo || !$photo->file_crop()) {
		print $q->header(-status => 404);
		print "Photo $round/$number not found\n";
	} else {
		$photo->{size} = $size;
		if($photo->resize()) {
			print $q->header("text/plain");
			print "Resized photo $round/$number to $size\n";
		} else {
			print $q->header(-status => 500);
			print "Error resizing photo $round/$number\n";
		}
	}

} else {
	print $q->header(-status => 400);
	print "Invalid input\n";
}
