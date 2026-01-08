#!/usr/bin/perl

# Create a directory with all of the photos from each of the photo sets, sorted
# by date.

use strict;

use lib::relative '../lib';

use Encode qw(decode);
use File::Copy;
use File::Path qw(make_path);
use Image::Magick;
use Jaeger::Photo;
use Jaeger::Photo::Set;
use Jaeger::User;

binmode STDOUT, ':utf8';

$Jaeger::User::Current = new Jaeger::User();
$Jaeger::User::Current->{status} = 20;

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
			decode("utf-8", $photo->description()));

		my $file = sprintf "%04d-%s_%s-%s.jpg",
			$i, $photo->{round}, $photo->{number}, $name;
		unless(-f "$dir/$file") {
			print "$file (",
		       		decode("utf-8", $photo->description()),
				")\n";
			if($photo->file_crop()) {
				# Check if the photo is larger than the
				# 1600x1200. (This is larger than my current
				# picture frame, but it's still within the
				# grasp of the picture frame. As of 2022-08, my
				# picture frame is a NIX-10H, with a screen
				# resolution of 1280x800.)
				my $img = new Image::Magick;
				$img->Read($photo->file_crop());
				my ($width, $height) = $img->Get('width', 'height');
				if($width > 1600 || $height > 1200) {
					# Resize the 
					$img->Resize(geometry => "1600x1200>");
					my $err = $img->Write("$dir/$file");
					if("$err") {
						warn "$err";
					}
				} else {
					# Copy the existing photo directly
					copy($photo->file_crop(), "$dir/$file")
						or warn "Can't copy ",
							$photo->{round}, "_",
							$photo->{number}, ": $!\n";
				}
				$new++;
			} else {
				warn "Photo not found: $photo->{round}_$photo->{number}\n";
			}
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
