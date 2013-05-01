#!/usr/bin/perl

#
# $Id: photos.pl,v 1.6 2007-03-10 02:42:06 jaeger Exp $
#

# Eventually, this will allow importing completely new rounds into the
# Great and Epic Photo Database. But for the moment, we'll require that the
# rounds already have been inserted.

# fix:
# (1) Importing new rounds, with time zones
# (2) Locations of photos

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";
use Jaeger::Photo;

use Data::Dumper;
use FileHandle;
use POSIX qw(strftime);
use Image::EXIF;
use Date::Parse;

autoflush STDOUT 1;

unless(@ARGV) {
	die "What rounds to import?\n";
}

my $new = 0;
if(grep /--new/, @ARGV) {
	$new = 1;
	@ARGV = grep !/--new/, @ARGV;
}

# The number of seconds to _add_ to the time to adjust for the camera's clock
# being behind
my $time_adjust = 0;

# The time zone that the _camera_'s clock was set to. For most (non-networked)
# cameras, this will be constant; I tend to keep my camera's clock set to local
# (Mountain) time and change it with daylight savings twice a year. Though it's
# not entirely uncommon for the time zone to lag by a couple of months.
#
# For mobile phones (and other devices that set their clock more frequently),
# this will be updated whenever I cross a time zone boundary, except for photos
# taken in flight or in places where a network time is not available for
# whatever reason.
my $camera_timezone;

# Should we ask what the camera timezone is for each photo? This should be set
# to a true value for mobile phone pictures, and false otherwise.
my $ask_camera_timezone = 0;

# The time zone that the _photo_ was taken in. This will change according to
# whatever I consider the 'local time' to be.
my $photo_timezone;

my $ask_photo_timezone = 0;

foreach my $round (@ARGV) {
	if($round eq '272' || $round eq '274') {
		# Parameters for rounds 272, 274, taken with my Nikon D50 in
		# Hong Kong
		$time_adjust = -503;
		$camera_timezone = Jaeger::Timezone->Select(name => 'MDT');
		$photo_timezone = Jaeger::Timezone->Select(name => 'HKT');
	} elsif($round eq '275') {
		# Parameters for round 275, taken with Kiesa's iPhone
		$time_adjust = 0;
		$camera_timezone = Jaeger::Timezone->Select(name => 'HKT');
		$photo_timezone = Jaeger::Timezone->Select(name => 'HKT');
	} elsif($round eq '273' || $round eq '277') {
		# Parameters for rounds 273 and 277, taken with my smartphone
		$ask_camera_timezone = 1;
		$ask_photo_timezone = 1;
	} elsif($round eq '278') {
		$time_adjust = 0;
		$camera_timezone = Jaeger::Timezone->Select(name => 'MST');
		$ask_photo_timezone = 1;
	} else {
		# Parameters for other rounds
		$time_adjust = 0;
		$camera_timezone = Jaeger::Timezone->Select(name => 'MDT');
		$photo_timezone = Jaeger::Timezone->Select(name => 'MDT');
	}
	annotate_round($round, $new);
}

if(@ARGV) {
	# Automatically update the thumbnails on the server
	#
	# Note that ssh executes this command in a non-login shell, so any
	# necessary environment variables (namely, $BCFS) must be set in
	# .bashrc before the interactive-shell test.
	system "ssh honor2.festing.org src/bcfs/bin/thumbnail.pl @ARGV";
}

exit;

#
# Annotate an already-existing set of photos
#
sub annotate_round {
	my $round = shift;
	my $new = shift;

	my %photos = map { ("$_->{round}/$_->{number}", $_) }
		Jaeger::Photo->Select("round = '$round' order by number");

	# Check to see if there are extra photos (if the import was aborted)
	foreach my $new_photo (import_round($round)) {
		my $desc = "$new_photo->{round}/$new_photo->{number}";
		unless($photos{$desc}) {
			$photos{$desc} = $new_photo;
		}
	}

	print "Round $round: ", scalar(keys %photos), " photos\n";

	foreach my $p (sort keys %photos) {
		if($new && !$photos{$p}->{hidden} && $photos{$p}->{id}) {
			my $photo = $photos{$p};
			print "\n";
			print $photo->{round}, '/', $photo->{number}, ': ',
				$photo->date_format(), "\n";
			if($photo->{description}) {
				print $photo->{description}, "\n";
			}
			next;
		}
		annotate_photo($photos{$p});
	}
}

#
# Show the photo to the user and solicit the photo's description
#
sub annotate_photo {
	my $photo = shift;

	# does a cropped photo exist? if not, this photo should be hidden
	unless($photo->file_crop()) {
		# flag photo as hidden and move on to the next one
		$photo->{hidden} = 'true';
#		$photo->update();
		return;
	}

	# read the date from the EXIF date and time
	# (The timestamp will be in the _camera's_ local time,
	# which may be different from the _photo's_ local time.
	# This will be adjusted later.)
	my $exif = new Image::EXIF($photo->file_raw());
	if($exif && $exif->get_other_info()) {
		my $date = $exif->get_other_info()
			->{'Image Generated'};
		unless($date) {
			$date = $exif->get_image_info()
				->{'Image Created'};
		}
		if($date) {
			$photo->{exifdate} = str2time($date,
				"GMT");
		} else {
			warn "EXIF tags not recogonized for ",
				$photo->file_raw(), "\n";
			print Dumper($exif->get_all_info());
		}
	}

	unless($photo->{exifdate}) {
		warn "Exif info not found for ",
			$photo->file_raw(), "\n";
		$photo->{exifdate} =
			(stat $photo->file_raw())[9];
	}
	$photo->{date} = $photo->{exifdate};

	unless($photo->{timezone_id}) {
		if($ask_photo_timezone || !defined($photo_timezone)) {
			print $photo->{round}, '/', $photo->{number}, ': ';
			$photo_timezone =
				get_timezone("Photo", $photo_timezone);
		}
		$photo->{timezone} = $photo_timezone;
	}
	unless($photo->{location_id}) {
		$photo->{location_id} = 1;
	}

	if($photo->{exifdate}) {
		# If this is a new photo, adjust the timestamp by the given
		# adjustment
		$photo->{date} = $photo->{exifdate} + $time_adjust;

		if($ask_camera_timezone || !defined($camera_timezone)) {
			print $photo->{round}, '/', $photo->{number}, ': ';
			$camera_timezone =
				get_timezone("Camera", $camera_timezone);
		}

		# And the time zone adjustment
		$photo->{date} -= $camera_timezone->ofst() * 3600;
	}

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
		system "eog \"" . $photo->file() . "\" >/dev/null 2>&1";

		# Wait to be killed by the parent
		while(1) {
			sleep 600;
		}
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
	unless($photo->{location_id}) {
		$photo->{location_id} = 1;
	}

	if($descript) {
		# Try to geotag the photo
		my $point = $photo->geotag();
		if($point) {
			print "Coordinates: $point\n";
		}

		$photo->{description} = $descript;
		# Set the mtime to the current time (in GMT)
		$photo->{mtime} = strftime("%Y-%m-%d %H:%M:%S+00", localtime);
		$photo->update();
	}

	# kill the photo display
	kill 1, $child_pid;
	wait;
}

#
# Insert a brand new round into the photo database, and return an array of
# the photo objects created
#
sub import_round {
	my $round = shift;

	unless(-d "$Jaeger::Photo::Dir/$round") {
		die "Round $round does not exist\n";
	}

	my %photos;

	# read the uncropped photos
	if(-d "$Jaeger::Photo::Dir/$round/raw") {
		print "Round $round: Scanning raw photos ";

		opendir DIR, "$Jaeger::Photo::Dir/$round/raw";

		foreach my $file (grep /\.jpg/, readdir DIR) {
			print '.';

			my ($number) = $file =~ /(.*)\.jpg/;

			my $photo = new Jaeger::Photo;
			$photo->{round} = $round;
			$photo->{number} = $number;

=for later
			# read the date from the EXIF date and time
			# (The timestamp will be in the _camera's_ local time,
			# which may be different from the _photo's_ local time.
			# This will be adjusted later.)
			my $exif = new Image::EXIF($photo->file_raw());
			if($exif && $exif->get_other_info()) {
				my $date = $exif->get_other_info()
					->{'Image Generated'};
				unless($date) {
					$date = $exif->get_image_info()
						->{'Image Created'};
				}
				if($date) {
					$photo->{exifdate} = str2time($date,
						"GMT");
				} else {
					warn "EXIF tags not recogonized for ",
						$photo->file_raw(), "\n";
					print Dumper($exif->get_all_info());
				}
			}

			unless($photo->{exifdate}) {
				warn "Exif info not found for ",
					$photo->file_raw(), "\n";
				$photo->{exifdate} =
					(stat $photo->file_raw())[9];
			}
			$photo->{date} = $photo->{exifdate};
=cut

			$photos{$number} = $photo;
		}

		closedir DIR;

		print "\n";
	}

	# read the cropped photos
	if(-d "$Jaeger::Photo::Dir/$round/new") {
		print "Round $round: Scanning cropped photos ";

		opendir DIR, "$Jaeger::Photo::Dir/$round/new";

		foreach my $file (grep /\.jpg/, readdir DIR) {
			print '.';

			my ($number) = $file =~ /(.*)\.jpg/;

			unless($photos{$number}) {
				my $photo = new Jaeger::Photo;
				$photo->{round} = $round;
				$photo->{number} = $number;
				$photos{$number} = $photo;
			}
		}

		closedir DIR;

		print "\n";
	}

	return sort {$a->{number} <=> $b->{number}} values %photos;
}

# Ask the user for a timezone
sub get_timezone {
	my $what = shift;
	my $old_timezone = shift;

	my $new_timezone = undef;

	do {
		print "$what timezone: ";
		if($old_timezone) {
			print "[", $old_timezone->{name}, "] ";
		}
		my $name = <STDIN>;
		chomp $name;
		if($name eq '') {
			$new_timezone = $old_timezone;
		} else {
			$new_timezone = Jaeger::Timezone->Select(name => $name);
			if($new_timezone) {
				printf "Selected timezone %s (GMT%+d)\n",
					$name, $new_timezone->{ofst};
			} else {
				print "Unrecogonized timezone '$name'\n";
			}
		}
	} while(!defined($new_timezone));

	return $new_timezone;
}
