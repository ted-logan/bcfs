#!/usr/bin/perl

use strict;

use POSIX;

my $photodir = '/home/jaeger/graphics/photos/dc';

my @import_dirs = (
	'/media/D5200/DCIM/100D5200',
	'/home/jaeger/.gvfs/mtp/Internal storage/DCIM/100MEDIA',
);

my @imports;

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
	system("cd $photodir && ./todo.pl && ./sync_to_ziyal.sh") == 0
		or die "Can't finish photo import\n";
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
