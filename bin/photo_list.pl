#!/usr/bin/perl

# Select and export a list of hand-chosen photos

use strict;

use File::Copy;
use File::Path qw(make_path);
use URI;

use lib::relative '../lib';

use Jaeger::Photo;

my @list = qw(
https://jaeger.festing.org/photo/2019/08/18/julian-and-calvin-ride-luas-in-dublin
https://jaeger.festing.org/photo/2019/11/30/calvin-sits-on-a-minecraft-bench
https://jaeger.festing.org/photo/2019/12/01/julian-under-the-christmas-tree
https://jaeger.festing.org/photo/2019/12/15/julian-watches-calvin-play-minecraft
https://jaeger.festing.org/photo/2019/11/24/julian-at-the-museum-of-flight
https://jaeger.festing.org/photo/2019/11/24/julian-in-an-f-a-18l-cockpit
https://jaeger.festing.org/photo/2019/10/31/calvin-and-julian-dressed-up-for-halloween-2
https://jaeger.festing.org/photo/2019/08/21/jaeger-calvin-and-julian-on-a-viking-splash-tour
https://jaeger.festing.org/photo/2019/02/21/julian-rides-the-royal-joust-at-legoland-2
https://jaeger.festing.org/photo/2019/02/04/julian-plays-in-the-snow
https://jaeger.festing.org/photo/2019/11/24/calvin-rides-on-a-playground-fuel-truck-behind-julian-and-caleb
https://jaeger.festing.org/photo/2019/06/29/cousins-julian-caleb-and-calvin-in-a-tree
);

my $path = "/home/jaeger/graphics/photos/2019-12-19";

unless(-d $path) {
	make_path($path);
}

foreach my $url (@list) {
	my $uri = new URI($url);
	my $photo = Jaeger::Photo->Select(uri => $uri->path());
	unless($photo) {
		warn "Could not find photo matching $url\n";
		next;
	}

	my $new_filename = $uri->path();
	$new_filename =~ s/^\/photo\///;
	$new_filename =~ s/\//-/g;
	$new_filename .= ".jpg";

	$photo->{size} = 'full';
	print "$url\n";
	print $photo->file(), " -> $new_filename\n";
	copy($photo->file(), "$path/$new_filename")
		or warn "Error copying file: $!\n";
	print "\n";
}
