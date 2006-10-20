#!/usr/bin/perl

#
# $Id: photos.pl,v 1.5 2006-10-20 02:11:52 jaeger Exp $
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

use FileHandle;

autoflush STDOUT 1;

unless(@ARGV) {
	die "What rounds to import?\n";
}

my $new = 0;
if(grep /--new/, @ARGV) {
	$new = 1;
	@ARGV = grep !/--new/, @ARGV;
}

foreach my $round (@ARGV) {
	annotate_round($round, $new);
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

	# FIXME set the time zone intelligently
	unless($photo->{timezone_id}) {
		$photo->{timezone} = Jaeger::Timezone->Select(name => 'MST');
	}
	unless($photo->{location_id}) {
		$photo->{location_id} = 1;
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
		system "eog \"" . $photo->file() . "\" >/dev/null";

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
		$photo->{description} = $descript;
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

			# read the date from the file date and time
			$photo->{date} = (stat $photo->file_raw())[9];

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
