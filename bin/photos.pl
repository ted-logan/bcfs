#!/usr/bin/perl

#
# $Id: photos.pl,v 1.1 2003-01-20 19:37:08 jaeger Exp $
#

# Eventually, this will allow importing completely new rounds into the
# Great and Epic Photo Database. But for the moment, we'll require that the
# rounds already have been inserted.

# fix:
# (1) Importing new rounds, with time zones
# (2) Locations of photos

use strict;

use lib '/home/jaeger/programming/webpage/lib';
use Jaeger::Photo;

use Image::Magick;

unless(@ARGV) {
	die "What rounds to import?\n";
}

foreach my $round (@ARGV) {
	import_round($round);
}

exit;

sub import_round {
	my $round = shift;

	my @photos = Jaeger::Photo->Select("round = '$round' order by number");

	print "Round $round: ", scalar(@photos), " photos\n";

	foreach my $photo (@photos) {
		import_photo($photo);
	}
}

sub import_photo {
	my $photo = shift;

	# does a cropped photo exist? if not, this photo should be hidden
	unless($photo->file_crop()) {
		# flag photo as hidden and move on to the next one
		$photo->{hidden} = 'true';
		$photo->update();
		return;
	}

	# make sure this photo is not flagged as hidden
	$photo->{hidden} = 'false';

	# show the photo
	my $child_pid = fork();
	unless(defined $child_pid) {
		die "Fork failed! $!\n";
	}
	if($child_pid == 0) {
		# child process

		# show the photo
		my $img = new Image::Magick;
		$img->Read($photo->file());

		# this function will block until it's killed by the parent
		$img->Display();

		# we should never, ever get here
		die "Child process: braindamage! display() returned?\n";
	}

	# parent process

	# get the description of the photo
	print "\n";
	print $photo->{round}, '/', $photo->{number}, ': ',
		$photo->date_format(), "\n";
	if($photo->{description}) {
		print $photo->{description}, "\n";
	}
	print "Description: ";
	my $descript = <STDIN>;
	chomp $descript;

	# FIXME get the location of the photo

	if($descript) {
		$photo->{description} = $descript;
		$photo->update();
	}

	# kill the photo display
	kill 1, $child_pid;
	wait;
}
