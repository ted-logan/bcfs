#!/usr/bin/perl

# Select at random one featured photo from the somewhat-arbitrary list of
# 'notable photos'; where a photo is 'notable' if:
#
# - it's one of the 100 most recent photos (with status = 0)
# - it's in any of the photo sets (with status = 0)
#
# Note that, if a photo appears on multiple sets (or is in the 100 most recent
# photos plus one or more sets), it is considered to be 'more notable', and is
# (by design) more likely to appear.
#
# I would like to expand this to include a larger back list of photos, but not
# most of the embarassingly-old photos from, say, 1998 to 2002. But without
# going back and protecting old photos I don't have a good way to rationalize
# the photos not covered in the list above.

use strict;

use lib "$ENV{BCFS}/lib";
use Jaeger::Lookfeel;
use Jaeger::Photo;
use Jaeger::Photo::Recent;

# Select all photos from all sets
my @photos_from_sets = Jaeger::Photo->Select(
	"id in (select photo_id from photo_set_map) and status = 0 and not hidden");

print "Found ", scalar(@photos_from_sets), " photos from sets\n";

my $recent_photos = new Jaeger::Photo::Recent;
my @last_100_photos = @{$recent_photos->photos()};

print "Found ", scalar(@last_100_photos), " recent photos\n";

my @notable_photos = (
	@photos_from_sets,
	@last_100_photos,
);

print "Considering ", scalar(@notable_photos), " notable photos\n";

my $featured = @notable_photos[rand @notable_photos];

print "Picked notable photo: ", $featured->description(), "\n";
print $featured->url(), "\n";

# Write the featured photo template
my $lf = new Jaeger::Lookfeel;
$featured->{size} = "256x192";
$featured->resize();
my $html = $lf->featured_photo_template(
	url => $featured->url(),
	thumbnail => "/digitalpics/$featured->{round}/$featured->{size}/$featured->{number}.jpg",
	description => $featured->description(),
);

Jaeger::Lookfeel->Update('featured_photo', $html);
