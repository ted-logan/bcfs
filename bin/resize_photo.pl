#!/usr/bin/perl -T

#
# $Id: resize_photo.pl,v 1.3 2006-08-13 02:25:56 jaeger Exp $
#

# Resize a photo

use strict;

BEGIN { $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin'; };

use lib '/home/jaeger/src/bcfs/lib';
use Jaeger::Photo;

use Image::Magick;

if(@ARGV != 3) {
	die "$0: ROUND NUMBER SIZE\n";
}

my $round = shift;
my $number = shift;
my $size = shift;

# untaint inputs. round and photo should be alphanumeric; size should be 
# formatted like 640x480
($round) = $round =~ /^([A-Za-z0-9_-]+)$/;
($number) = $number =~ /^([A-Za-z0-9_-]+)$/;
my ($width, $height) = $size =~ /^([0-9]+)x([0-9]+)$/;

# Verify that the photo exists
my $photo = Jaeger::Photo->Select(round => $round, number => $number);
unless($photo) {
	die "Photo $round/$number doesn't exist!\n";
}

# Make the correct directory, if it doesn't already exist
my $newdir = "$Jaeger::Photo::Dir/$round/${width}x${height}";
unless(-d $newdir) {
	mkdir $newdir;
}

my $newfile = "$newdir/$number.jpg";

if($photo->native() eq "${width}x${height}") {
	my $oldfile = $photo->file_crop();
#	warn "Symlinking $newfile ($oldfile)\n";

	unless(symlink $oldfile, $newfile) {
		die "Symlink failed: $!\n";
	}

	exit;
}

# Determine the size of the photo
my $img = new Image::Magick;
$img->Read($photo->file());

my ($owidth, $oheight) = $img->Get('width', 'height');

#warn "Original size is $owidth x $oheight; desired is $width x $height\n";

my ($nwidth, $nheight);

my $aspect = $owidth / $oheight;
if($aspect > ($width / $height)) {
	$nwidth = $width;
	$nheight = int($width / $aspect);
} else {
	$nwidth = int($height * $aspect);
	$nheight = $height;
}

#warn "New size is $nwidth x $nheight (aspect is ", ($nwidth / $nheight), ")\n";

if(($nwidth > $owidth) || ($nheight > $oheight)) {
	die "New size is larger than original size\n";
}

$img->Resize(width => $nwidth, height => $nheight);

$img->Write($newfile);

#warn "Writing $newfile (${nwidth}x${nheight})\n";
