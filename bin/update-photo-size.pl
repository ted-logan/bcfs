#!/usr/bin/perl

# Find all photos in the database that are visible and have a null width or
# height. Update their width and height from the physical dimensions of the
# photo.

use strict;

use lib::relative '../lib';

use Jaeger::Photo;
use Jaeger::User;

binmode STDOUT, ':utf8';

$Jaeger::User::Current = new Jaeger::User();
$Jaeger::User::Current->{status} = 30;

my $where = "(width is null or height is null) and not hidden";

foreach my $photo (Jaeger::Photo->Select($where)) {
	printf "%s/%s: %s\n", $photo->round(), $photo->number(),
       		$photo->description();

	# Update the width and height of the photo stored in the database
	my $img = new Image::Magick;
	$img->Read($photo->file_crop());
	my ($width, $height) = $img->Get('width', 'height');
	$photo->{width} = $width;
	$photo->{height} = $height;

	printf "\t%dx%d\n", $width, $height;

	$photo->update();
}
