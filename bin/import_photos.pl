#!/usr/bin/perl

use strict;

use POSIX;

my $photodir = '/home/jaeger/graphics/photos/dc';
my $local_backup = '/media/jaeger/neuromancer/home/jaeger/graphics/photos/dc/';
my $google_drive_dir = '/home/jaeger/gdrive/Google Photos';

my @import_dirs = (
	'/media/D5200/DCIM/100D5200',
	'/media/jaeger/D5200/DCIM/100D5200',
	'/media/jaeger/NIKON D5200/DCIM/100D5200',
	'/home/jaeger/.gvfs/mtp/Internal storage/DCIM/100MEDIA',
	<'/home/jaeger/.gvfs/gphoto2 mount on usb*/DCIM/100MEDIA'>,
	<'/run/user/*/gvfs/*/Internal shared storage/DCIM/Camera'>,
	<'/run/user/*/gvfs/*/GoPro MTP Client Disk Volume/DCIM/100GOPRO'>,
	<'/run/user/*/gvfs/*/DCIM/*'>,
);

# Individual files that are imported are stored in this array
my @imports;

# Each new round is stored in this array
my @new_rounds;

if(grep @ARGV, "--gdrive") {
	# Import new photos from THE CLOUD, namely, Google Drive.

	chdir $google_drive_dir
		or die "Unable to chdir to drive dir $google_drive_dir: $!";

	# Pull updates from THE CLOUD
	system("drive pull -no-prompt") == 0
		or die "Unable to update photos from Google Photos: $!";

	# Find all jpegs newer than the last file imported from Google Photos
	open LAST, "$photodir/.last_gphoto"
		or die "Can't open .last_gphoto: $!";
	my $last_gphoto = <LAST>;
	chomp $last_gphoto;
	close LAST;

	unless(-f $last_gphoto) {
		die "Last gphoto $last_gphoto is missing";
	}
	my $mtime = (stat(_))[9];

	my %new_files;
	my $newest;
	foreach my $file (<*>) {
		next if $file =~ /^\./;
		next unless -f $file;
		next unless $file =~ /\.jpg$/i;
		my $file_mtime = (stat(_))[9];
		next unless $file_mtime > $mtime;

		if(!defined($newest) || $newest->{mtime} < $file_mtime) {
			$newest = {
				mtime => $file_mtime,
				file => $file,
			};
		}

		# Clean up the file name a bit
		my $file_import = $file;
		$file_import =~ s/\.jpg/.jpg/i;
		$file_import =~ s/~\d?//;
		$file_import =~ s/-/_/g;

		if(exists $new_files{$file_import}) {
			die "Duplicate file: $file_import " .
				"(from $file, existing " .
				"$new_files{$file_import}";
		}
		$new_files{$file_import} = $file;
	}

	if(%new_files) {
		die "New files but no newest file?" unless $newest;

		# We have set of new files to import. Create a directory, and
		# hard-link them over.

		my $round = new_round();
		push @new_rounds, $round;
		printf "Importing %d photos from %s to new round %s\n",
			scalar(keys %new_files), "Google Photos", $round;

		foreach my $file (keys %new_files) {
			print $file;
			if($file ne $new_files{$file}) {
				print " ($new_files{$file})";
			}
			print "\n";
			link $new_files{$file}, "$photodir/$round/raw/$file"
				or die "Can't create link from " .
					"$new_files{$file} to " .
					"$photodir/$round/raw/$file: $!";
		}

		open LAST, ">", "$photodir/.last_gphoto"
			or die "Can't open .last_gphoto: $!";
		print LAST $newest->{file}, "\n";
		close LAST;
	}
}

my %last_photo;
my %last_photo_mtime;

foreach my $dir (sort @import_dirs) {
	next unless -d $dir;
	next unless opendir DIR, $dir;
	print "Reading directory $dir\n";
	my @files = sort grep {/^[^.]/ && /\.(jpe?g|mp4)$/i} readdir DIR;
	closedir DIR;

	unless(scalar(@files)) {
		warn "Ignoring empty import directory $dir\n";
		next;
	}

	my $normalize = 1;
	my $unlink = 1;
	my $iphone = 0;

	# For Android, I can put the .last_photo marker file in the same
	# directory on the device. This doesn't seem to work on iOS, so keep a
	# separate marker file
	#
	# This basically relies on my only ever importing photos from one iOS
	# device, so I guess that's a bridge I'll burn when I get to it.
	my $last_photo_file;
	if(-f "$dir/.last_photo") {
		$last_photo_file = "$dir/.last_photo";
	} elsif($dir =~ /\d\d\d\d\d\d__/) {
		$last_photo_file = "$photodir/.last_iphone_photo";
		$iphone = 1;
	}

	if($last_photo_file) {
		open(my $fh, "<", $last_photo_file)
			or die "Can't open $last_photo_file: $!\n";

		my $last_photo = <$fh>;
		chomp $last_photo;
		close $fh;

		my $last_photo_mtime = (stat($last_photo_file))[9];

		print "Last photo is \"$last_photo\" at ",
			scalar(localtime($last_photo_mtime)), "\n";
		print "There are a total of ", scalar(@files), " candidate files in the input directory\n";

		@files = grep {$_ !~ /\.mp4$/i} @files;

		if($iphone) {
			# On iPhone, select photos to import that have an mtime
			# greater than the last imported timestamp
			@files = grep {(stat($dir . '/' . $_))[9] > $last_photo_mtime} @files;
			@files = grep /^IMG_\d\d\d\d.JPG$/, @files;
		} else {
			# On Android, select photos to import that are
			# lexographically greater than the last photo imported
			@files = grep {$_ gt $last_photo} @files;
		}

		unless(scalar(@files)) {
			warn "No photos newer than last photo \"$last_photo\", ignoring import directory $dir\n\n";
			next;
		}

		print "Selecting only the ", scalar(@files), " files newer than last photo \"$last_photo\"\n";
		print map { "\t$_\n"} @files;

		$normalize = 0;
		$unlink = 0;

		$last_photo{$last_photo_file} = @files[-1];
		$last_photo_mtime{$last_photo_file} =
			(stat($dir . '/' . @files[-1]))[9];
	} else {
		printf "Found %d files in %s\n", scalar(@files), $dir;
	}

	my $round = new_round();
	push @new_rounds, $round;

	printf "Importing %d photos from %s to new round %s\n",
		scalar(@files), $dir, $round;

	my $places = ceil(log(scalar @files) / log(10));

	my $count = 0;
	foreach my $file (@files) {
		my $newfile;
		$count++;
		if($dir =~ /100GOPRO/) {
			$newfile = lc $file;
			$newfile =~ s/^..../GOPRO/;
			printf "%s -> %s (%d of %d)\n",
				$file, $newfile, $count, scalar(@files);

		} elsif($normalize) {
			$newfile = sprintf "%0${places}d.jpg", $count;
			printf "%s -> %s (%d of %d)\n",
				$file, $newfile, $count, scalar(@files);

		} else {
			$newfile = $file;
			$newfile =~ s/\.NIGHT//;
			$newfile =~ s/\.JPG$/.jpg/;
			printf "%s -> %s (%d of %d)\n",
				$file, $newfile, $count, scalar(@files);
		}

		system(sprintf("cp -a -i \"%s/%s\" \"%s/%s/raw/%s\"",
			$dir, $file, $photodir, $round, $newfile)) == 0
			or die "Unable to copy file $file: $!\n";
		chmod 0644, "$photodir/$round/raw/$newfile";

		if($unlink) {
			push @imports, "$dir/$file";
		}
	}
}

if(@new_rounds) {
	if(-d $local_backup) {
		# If the local backup directory is present, back up the new
		# photos there, rather than synchronizing them to my NAS on my
		# network at home
		foreach my $round (@new_rounds) {
			system("rsync -av --progress --exclude todo $photodir/$round $local_backup/") == 0
				or die "Can't finish photo import ($round)\n";
		}
		system("cd $photodir && ./todo.pl") == 0
			or die "Can't finish photo import\n";
	} else {
		# If the local backup directory is not present, try to sync all
		# photos to long-term storage on Breq
		system("cd $photodir && ./todo.pl && ./sync_to_breq.sh") == 0
			or die "Can't finish photo import\n";
	}
	unlink @imports;
} else {
	print "No photos to import\n";
}

foreach my $last_photo_file (keys %last_photo) {
	unless(open(LAST, ">", $last_photo_file)) {
		warn "Can't write last photo file $last_photo_file: $!\n";
		next;
	}

	print LAST $last_photo{$last_photo_file}, "\n";

	close LAST;

	utime($last_photo_mtime{$last_photo_file},
		$last_photo_mtime{$last_photo_file},
		$last_photo_file)
		or warn "Can't set last photo mtime for $last_photo_file: $!";
}

# Identifies the next numbered round
sub new_round {
	opendir(my $dh, $photodir)
		or die "Can't open photo dir $photodir: $!\n";
	my @rounds = sort grep /^\d+$/, readdir $dh;
	closedir $dh;

	my $round = $rounds[-1] + 1;

	mkdir "$photodir/$round"
		or die "Can't make directory $photodir/$round: $!\n";
	mkdir "$photodir/$round/raw"
		or die "Can't make directory $photodir/$round/raw: $!\n";

	return $round;
}
