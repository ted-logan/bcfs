#!/usr/bin/perl

# calvin/calvin.pl: Maintains a directory with photos matching the text "Calvin"

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;

my $directory = '/home/jaeger/graphics/photos/calvin';

my $where = "description ilike '%calvin%' and not hidden order by date desc";
my @photos = Jaeger::Photo->Select($where);

my %contents_of_dir = do {
	opendir(my $dh, $directory) || die "can't open $directory: $!\n";
	my @c = grep !/^\./, readdir $dh;
	closedir $dh;
	map {$_, undef} @c;
};

foreach my $photo (@photos) {
	my $file = sprintf "%s_%s.jpg", $photo->round(), $photo->number();
	unless(-f $file) {
		printf "%s -> %s\n", "$directory/$file", $photo->file_crop();
		link($photo->file_crop(), "$directory/$file")
			|| die "Can't create symlink: $!\n";
	}
	if(exists $contents_of_dir{$file}) {
		delete $contents_of_dir{$file};
	}
}

unlink map { "$directory/$_" } keys %contents_of_dir;
