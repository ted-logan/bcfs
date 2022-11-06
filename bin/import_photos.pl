#!/usr/bin/perl

use strict;

use POSIX;

my $photodir = '/home/jaeger/graphics/photos/dc';
my $local_backup = '/media/jaeger/neuromancer/home/jaeger/graphics/photos/dc/';

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

my %last_photo;
my %last_photo_mtime;

my $dryrun = 0;

if(grep /^-n$/, @ARGV) {
	$dryrun = 1;
}

chdir $photodir;
my %existing_files;
foreach my $existing_file (<"*/raw/*.jpg">) {
	my ($round, $number) = $existing_file =~ m#^(.*?)/raw/(.*?).jpg$#;
	push @{$existing_files{$number}}, $existing_file;
}

foreach my $dir (sort @import_dirs) {
	next unless -d $dir;
	next unless opendir DIR, $dir;
	my $display_dir = $dir;
	$display_dir =~ s/.*DCIM/DCIM/;
	print "Reading directory $display_dir\n";
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
			@files = grep /^IMG_\d+.JPG$/, @files;

			sub filter_existing_files {
				my $file = shift;
				my ($number) = $file =~ /^(.*).JPG/i;
				if(exists $existing_files{$number}) {
					print "Skipping $file\n";
					return 0;
				} else {
					return 1;
				}
			}

			# Also filter out files that already exist
			@files = grep {filter_existing_files($_)} @files;
		} else {
			# On Android, select photos to import that are
			# lexographically greater than the last photo imported
			@files = grep {$_ gt $last_photo} @files;
		}

		unless(scalar(@files)) {
			print "\n";
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

	my $round;
	if($dryrun) {
		$round = "DRYRUN";
	} else {
		$round = new_round();
		push @new_rounds, $round;
	}

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

		unless($dryrun) {
			system(sprintf("cp -a -i \"%s/%s\" \"%s/%s/raw/%s\"",
				$dir, $file, $photodir, $round, $newfile)) == 0
				or die "Unable to copy file $file: $!\n";
			chmod 0644, "$photodir/$round/raw/$newfile";
		}

		if($unlink) {
			push @imports, "$dir/$file";
		}
	}

	print "\n";
}

if($dryrun) {
	exit;
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
