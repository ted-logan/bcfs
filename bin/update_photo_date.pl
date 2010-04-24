#!/usr/bin/perl

# Update the "mtime" date stamp in the photo database based on the mtime on the
# filesystem for non-hidden photos.

# This script was used to set the mtime for existing photos; the code in
# photos.pl is used to set the mtime for new photos.

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";
use Jaeger::Photo;

use POSIX qw(strftime);

my @photos = Jaeger::Photo->Select("not hidden and mtime is null");

foreach my $photo (@photos) {
	my $file = $photo->file_crop();
	if($file) {
		my $mtime = strftime("%Y-%m-%d %H:%M:%S+00",
			localtime((stat $file)[9]));
		printf "%s/%s: %s\n",
			$photo->round(),
			$photo->number(),
			$mtime;
		$photo->{mtime} = $mtime;
		$photo->update();
	}
}
