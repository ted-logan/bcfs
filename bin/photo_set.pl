#!/usr/bin/perl

# Create a directory with all of the photos from each of the photo sets, sorted
# by date.

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";
use File::Copy;
use File::Path qw(make_path);
use Jaeger::Photo;
use Jaeger::Photo::Set;
use Jaeger::User;

$Jaeger::User::Current = new Jaeger::User();
$Jaeger::User::Current->{status} = 10;

foreach my $set (Jaeger::Photo::Set->Select()) {
	my $dir = $set->directory();
	printf "%d: %s (%s)\n", $set->id(), $set->name(), $dir;

	unless(-d $dir) {
		make_path($dir);
	}

	my %old = do {
		opendir DIR, $dir;
		my @files = grep /\.jpg$/, readdir DIR;
		closedir DIR;
		map {$_, undef} @files;
	};

	my $i;

	my $total = 0;
	my $new = 0;

	foreach my $photo (@{$set->photos()}) {
		$i++;
		next if $photo->{hidden};

		my $name = Jaeger::Uri::MakeUriFromTitle(
			$photo->description());

		my $file = sprintf "%04d-%s_%s-%s.jpg",
			$i, $photo->{round}, $photo->{number}, $name;
		print "$file ($photo->{description})\n";
		unless(-f "$dir/$file") {
			copy($photo->file_crop(), "$dir/$file")
				or warn "Can't copy ",
					$photo->{round}, "_",
					$photo->{number}, ": $!\n";
			$new++;
		}
		$total++;
		delete $old{$file};
	}

	my $old = scalar keys %old;
	if($old) {
		unlink map {"$dir/$_"} keys %old;
	}

	print "\n";
	print "$total total pictures; $new new pictures, $old old pictures\n";
	print "\n";
}
