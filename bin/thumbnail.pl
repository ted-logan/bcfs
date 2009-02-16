#!/usr/bin/perl

#
# $Id: thumbnail.pl,v 1.2 2004-11-12 23:07:46 jaeger Exp $
#

# create thumbnail images for the given rounds if they don't already exist

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;

use Image::Magick;

my @rounds;

if(@ARGV) {
	@rounds = @ARGV;
} else {
	opendir DIR, $Jaeger::Photo::Dir
		or die "Can't open photo dir: $!\n";
	@rounds = sort grep {!/^\./ && -d "$Jaeger::Photo::Dir/$_"} readdir DIR;
	closedir DIR;
}

foreach my $round (@rounds) {
	unless(-d "$Jaeger::Photo::Dir/$round/thumbnail") {
		mkdir "$Jaeger::Photo::Dir/$round/thumbnail", 0755;
	}

	my @photos = Jaeger::Photo->Select(round => $round);

	foreach my $photo (@photos) {
		next if $photo->{hidden};

		print "$round/$photo->{number}: ", $photo->file(), "\n";

		next unless $photo->file();

		# figure out if we need to create or update the thumbnail
		if(!-f $photo->thumbnail() ||
				((stat $photo->thumbnail())[9] <
				(stat $photo->file())[9])) {
			print "\tUpdating thumbnail\n";

			my $img = new Image::Magick;
			$img->Read($photo->file());

			# we want to scale the image to fit within 128x96
			my ($x, $y) = $img->Get('columns', 'rows');
			if($x == 0 || $y == 0) {
				print "\tInvalid file!\n";
				next;
			}

			my $aspect = $x / $y;
			my ($newx, $newy);
			if($aspect > 4 / 3) {
				$newx = 128;
				$newy = 128 / $aspect;
			} else {
				$newy = 96;
				$newx = 96 * $aspect;
			}
			print "\t($x, $y) -> ($newx, $newy)\n";
			$img->Resize(width => $newx, height => $newy);
			$img->Write($photo->thumbnail());
		}
	}

}
