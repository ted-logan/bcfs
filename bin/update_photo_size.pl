#!/usr/bin/perl

# Updates the full image width or height in the database.

use strict;

use POSIX;
use Encode qw(decode);

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;
use Jaeger::Uri;
use Image::Magick;

binmode STDOUT, ':utf8';

my $iter = Jaeger::Photo->Prepare("not hidden order by rowkey");
while(my $photo = $iter->next()) {
	my $file = $photo->file_crop();

	unless($file) {
		warn "Cropped photo for $photo->{round}/$photo->{number} does not exist\n";
		next;
	}

	my $img = new Image::Magick;
	$img->Read($file);

	my ($width, $height) = $img->Get('width', 'height');

	if(($photo->{width} == $width) && ($photo->{height} == $height)) {
		# No change to photo size
		next;
	}

	print "$photo->{round}/$photo->{number}: ", $photo->date_format(), "  ",
		decode("utf-8", $photo->description()), "\n";
	print "\t${width}x${height}\n";

	$photo->{width} = $width;
	$photo->{height} = $height;

	$photo->update();
}
