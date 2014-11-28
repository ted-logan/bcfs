#!/usr/bin/perl

use strict;

use POSIX;

my $photodir = '/home/jaeger/graphics/photos/dc';
my $local_backup = '/media/neuromancer/home/jaeger/graphics/photos/dc/';

my @import_dirs = (
	'/media/D5200/DCIM/100D5200',
	'/home/jaeger/.gvfs/mtp/Internal storage/DCIM/100MEDIA',
);

# Individual files that are imported are stored in this array
my @imports;

# Each new round is stored in this array
my @new_rounds;

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
	mkdir "$photodir/$round"
		or die "Can't make directory $photodir/$round: $!\n";
	mkdir "$photodir/$round/raw"
		or die "Can't make directory $photodir/$round/raw: $!\n";
	push @new_rounds, $round;

	printf "Importing %d photos from %s to new round %s\n",
		scalar(@files), $dir, $round;

	my $places = ceil(log(scalar @files) / log(10));

	my $count = 0;
	foreach my $file (@files) {
		my $newfile = sprintf "%0${places}d.jpg", ++$count;

		printf "%s -> %s\n",
			$file, $newfile;

		system(sprintf("cp -a -v \"%s/%s\" \"%s/%s/raw/%s\"",
			$dir, $file, $photodir, $round, $newfile)) == 0
			or die "Unable to copy file $file: $!\n";
		chmod 0644, "$photodir/$round/raw/$newfile";

		push @imports, "$dir/$file";
	}
}

if(@imports) {
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

	return $rounds[-1] + 1;
}
