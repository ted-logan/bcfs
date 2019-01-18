#!/usr/bin/perl

use strict;

use POSIX;

my $photodir = '/home/jaeger/graphics/photos/dc';
my $local_backup = '/media/neuromancer/home/jaeger/graphics/photos/dc/';
my $google_drive_dir = '/home/jaeger/gdrive/Google Photos';

my @import_dirs = (
	'/media/D5200/DCIM/100D5200',
	'/media/jaeger/D5200/DCIM/100D5200',
	'/media/jaeger/NIKON D5200/DCIM/100D5200',
	'/home/jaeger/.gvfs/mtp/Internal storage/DCIM/100MEDIA',
	<'/home/jaeger/.gvfs/gphoto2 mount on usb*/DCIM/100MEDIA'>,
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

foreach my $dir (@import_dirs) {
	next unless -d $dir;
	next unless opendir DIR, $dir;
	my @files = sort grep /^[^.]/, readdir DIR;
	closedir DIR;

	unless(scalar(@files)) {
		warn "Ignoring empty import directory $dir\n";
		next;
	}

	my $round = new_round();
	push @new_rounds, $round;

	printf "Importing %d photos from %s to new round %s\n",
		scalar(@files), $dir, $round;

	my $places = ceil(log(scalar @files) / log(10));

	my $count = 0;
	foreach my $file (@files) {
		my $newfile = sprintf "%0${places}d.jpg", ++$count;

		printf "%s -> %s (of %d)\n",
			$file, $newfile, scalar(@files);

		system(sprintf("cp -a \"%s/%s\" \"%s/%s/raw/%s\"",
			$dir, $file, $photodir, $round, $newfile)) == 0
			or die "Unable to copy file $file: $!\n";
		chmod 0644, "$photodir/$round/raw/$newfile";

		push @imports, "$dir/$file";
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
		# photos to long-term storage on Hiro
		system("cd $photodir && ./todo.pl && ./sync_to_ziyal.sh") == 0
			or die "Can't finish photo import\n";
	}
	unlink @imports;
} else {
	print "No photos to import\n";
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
