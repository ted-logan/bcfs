package	Jaeger::Photo;

# 
# $Id: Photo.pm,v 1.10 2007-04-22 00:17:07 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Provides a handy-dandy interface for my vast digital photo collection

# created  05 January 2003

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

@Jaeger::Photo::ISA = qw(Jaeger::Base);

use Carp;

use Encode qw(decode);
use File::stat;

use Jaeger::Location;
use Jaeger::Timezone;
use Jaeger::GPS;
use Jaeger::PageRedirect;
use Jaeger::Uri;
use Jaeger::User;

use Jaeger::Photo::List;
use Jaeger::Photo::Year;

use Image::Magick;
use LWP::UserAgent;

sub table {
	return 'photo';
}

$Jaeger::Photo::Dir = '/home/jaeger/graphics/photos/dc';
$Jaeger::Photo::CacheDir = '/var/www/cache/dc';

@Jaeger::Photo::Sizes = qw(640x480 800x600 1024x768 1280x960 1600x1200 2048x1536 3000x2000);

# The size used for photos on the list pages
$Jaeger::Photo::ThumbnailSize = "256x192";
# The size used for photos embedded into changelogs
$Jaeger::Photo::ChangelogEmbedSize = "640x480";
# The size used for photos included in RSS feed
$Jaeger::Photo::FeedSize = "800x600";
# The size used for full-sized photos
$Jaeger::Photo::FullSize = "1600x1200";

# makes sure timezone_id and location_id are set
sub update {
	my $self = shift;

	unless($self->{timezone_id}) {
		if($self->{timezone}) {
			$self->{timezone_id} = $self->{timezone}->id();
		} else {
			carp "Jaeger::Photo->update(): timezone must be set";
			return undef;
		}
	}

	unless($self->{location_id}) {
		if($self->{location}) {
			$self->{location_id} = $self->{location}->id();
		} else {
			carp "Jaeger::Photo->update(): location must be set";
			return undef;
		}
	}

	# double-check the hidden boolean parameter
	if(!$self->{hidden} || $self->{hidden} =~ /^f/i) {
		$self->{hidden} = 'false';
	} else {
		$self->{hidden} = 'true';
	}

	unless($self->hidden()) {
		my $olduri = $self->{uri};

		$self->{uri} = $self->create_uri();

		unless($olduri) {
			warn "Creating new photo uri for ",
				"$self->{round}/$self->{number}:\n",
				"\t$self->{uri}\n";
		}

		if($olduri && $olduri ne $self->{uri}) {
			warn "Creating redirect for ",
				"$self->{round}/$self->{number}:\n",
				"\tfrom $olduri\n",
				"\tto $self->{uri}\n";

			my $redirect = new Jaeger::PageRedirect();
			$redirect->{uri} = $olduri;
			$redirect->{redirect} = $self->{uri};
			$redirect->update();
		}
	}

	unless(defined $self->{status}) {
		$self->{status} = 0;
	}

	$self->{rowkey} = $self->create_rowkey();

	$self->SUPER::update();
}

sub create_uri {
	my $self = shift;
	# If specified, all_uris is a reference to a hash containing all of the
	# photo uris that exist. This is specified during debugging this
	# algorithm, while updating all of the photo uris at once. In
	# production, we expect photos to be updated one at a time, so this
	# function will query the database for each photo.
	my $all_uris = shift;

	my $date;
	if($self->{date} == 0) {
		$date = $self->{round};
	} else {
		$date = POSIX::strftime("%Y/%m/%d",
			gmtime($self->{date} +
				$self->timezone()->ofst() * 3600));
	}

	my $title = decode("utf-8", $self->description());
	unless($title) {
		$title = "untitled";
	}
	$title = Jaeger::Uri::MakeUriFromTitle($title);

	my $uri = "/photo/$date/$title";

	# If this photo already has a uri, and the date and title are
	# unchanged, then keep the old uri.
	if($self->{uri}) {
		my $prefix = substr($self->{uri}, 0, length($uri));
		if($prefix eq $uri) {
			return $self->{uri};
		}
	}

	unless($all_uris) {
		# Most of the time we want to load the list of uris from the
		# database. Do this for the uris matching the base pattern
		# (because we don't actually care about everything).
		my $sql = "select uri from photo where uri like ?";
		$all_uris = $self->dbh()->selectall_hashref(
			$sql, "uri", {}, "$uri%");
	}

	my $count = 1;
	do {
		$uri = "/photo/$date/$title";
		if($count > 1) {
			$uri .= '-' . $count;
		}
		$count++;
	} while(exists $all_uris->{$uri});
	$all_uris->{$uri}++;

	return $uri;
}

# The rowkey is a string that uniquely defines the proper sort ordering for the
# photos. It is intended to be stored in an indexed column in the database to
# make it easy to look up the sort ordering, without constructing complicated
# sort queries to handle cases where there are multiple photos with the same
# date, or a photo has no date at all. Note that it is not literally the row
# key of the database, since the current implementation uses Postgresql not
# Bigtable.
sub create_rowkey {
	my $self = shift;

	my $date = POSIX::strftime("%Y-%m-%d-%H%M%S", gmtime($self->{date}));

	my $rowkey = "$date/$self->{round}/$self->{number}";

	return $rowkey;
}

# returns a Postgres-compatible date
sub date {
	my $self = shift;

	my @date = (gmtime($self->{date}))[0..5];
	$date[4]++;
	$date[5] += 1900;

	return sprintf("%04d-%02d-%02d %02d:%02d:%02d+00", reverse @date);
}

# selects this photo's timezone
sub _timezone {
	my $self = shift;

	return $self->{timezone} =
		Jaeger::Timezone->new_id($self->{timezone_id});
}

# selects this photo's location
sub _location {
	my $self = shift;

	return $self->{location} =
		Jaeger::Location->new_id($self->{location_id});
}

# formats the photo's date according to the time zone
sub _date_format {
	my $self = shift;

	return $self->{date_format} = $self->timezone()->format($self->{date});
}

# returns the physical path to the jpeg
sub _file {
	my $self = shift;

	if($self->{size}) {
		my $file = "$Jaeger::Photo::CacheDir/$self->{round}/$self->{size}/$self->{number}.jpg";
		if(-f $file) {
			return $self->{file} = $file;
		}
	}

	if($self->file_crop()) {
		return $self->{file} = $self->file_crop();
	}

	if($self->file_raw()) {
		return $self->{file} = $self->file_raw();
	}

	# this really shouldn't happen
	warn "braindamage: $self->{round}/$self->{number} has no photo\n";
	return undef;
}

# returns the physical path to the cropped jpeg, if it exists
sub _file_crop {
	my $self = shift;

	my $full = "$Jaeger::Photo::Dir/$self->{round}/full/$self->{number}.jpg";

	if(-f $full) {
		return $self->{file_crop} = $full;
	}

	my $crop = "$Jaeger::Photo::Dir/$self->{round}/new/$self->{number}.jpg";

	if(-f $crop) {
		return $self->{file_crop} = $crop;
	} else {
		return undef;
	}
}

# returns the physical path to the raw jpeg, if it exists
sub _file_raw {
	my $self = shift;

	my $raw_new = "$Jaeger::Photo::Dir/$self->{round}/raw/" .
		$self->{number} . ".jpg";

	if(-f $raw_new) {
		return $self->{file_raw} = $raw_new;
	}

	my $raw_old = "$Jaeger::Photo::Dir/$self->{round}/0000_" .
		($self->{number} =~ /^\d\d\d$/ ? '' : '0') .
		$self->{number} . ".jpg";

	if(-f $raw_old) {
		return $self->{file_raw} = $raw_old;
	} else {
		return undef;
	}
}

# returns the physical path to the thumbnail jpeg
sub _thumbnail {
	my $self = shift;

	return $self->{thumbnail} = "$Jaeger::Photo::CacheDir/$self->{round}/thumbnail/$self->{number}.jpg";
}

# returns a Perl-compatible boolean for the hidden boolean parameter
sub hidden {
	my $self = shift;

	if(!$self->{hidden} || $self->{hidden} =~ /^f/i) {
		return 0;
	} else {
		return 1;
	}
}

# figure out the size of the photo
sub size {
	# TODO deprecate this
	my $self = shift;

	if($self->{size}) {
		return $self->{size};
	}

	if($self->file_crop()) {
		return $self->{size} = $self->native();
	}

	if($self->file_raw()) {
		return $self->{size} = 'raw';
	}

	# The photo doesn't seem to exist. This could be bad.
	return undef;
}

# Return the photo size closest to the actual size, in 640x480
sub _native {
	# TODO deprecate this?
	my $self = shift;

	my $img = new Image::Magick;
	$img->Read($self->file_crop() ? $self->file_crop() : $self->file_raw());

	my ($width, $height) = $img->Get('width', 'height');

	my $lastsize = $Jaeger::Photo::Sizes[0];

	foreach my $size (@Jaeger::Photo::Sizes) {
		my ($w, $h) = $size =~ /(\d+)x(\d+)/;
		if(($w > $width) && ($h > $height)) {
			return $self->{native} = $lastsize;
		}
		$lastsize = $size;
	}

	return $lastsize;

#	return $self->{native} = "${width}x${height}";
}

# Make sure the photo exists for the desired size, in the cloud.
#
# This makes Cloud Storage API calls, so it will work from anywhere, but in
# practice it's easier to run it on my server in THE CLOUD.
sub resize {
	my $self = shift;

	my $size = shift;
	unless($size) {
		$size = $self->size();
	}

	return 1 if $self->{sizes} =~ /$size/;

	unless(system("$ENV{BCFS}/bin/cloud_resize.py " .
		"--round=\"$self->{round}\" " .
		"--number=\"$self->{number}\" " .
		"--size=\"$size\" > /dev/null") == 0) {

		warn "Photo $self->{round}/$self->{number}: Unable to resize to $size";
		return 0;
	}

	$self->{sizes} .= ',' . $size;

	return 1;
}

# Make sure the photo exists for the desired size, on the web server. This
# generates an HTTP call to thumbnail.cgi on the web server, which results in
# resize() being called.
sub remote_resize {
	my $self = shift;

	my $size = shift;
	unless($size) {
		$size = $self->size();
	}

	return 1 if $self->{sizes} =~ /$size/;

	my $url = $Jaeger::Base::BaseURL . "thumbnail.cgi?" .
		"round=$self->{round}&number=$self->{number}&size=$size";

	{
		local $| = 1;
		print "Resizing $self->{round}/$self->{number} to $size... ";
	}

	my $ua = new LWP::UserAgent;

	my $request = HTTP::Request->new(GET => $url);
	my $response = $ua->request($request);

	if($response->is_success()) {
		print "ok.\n";
	} else {
		print "error ", $response->code(), "\n";
		warn "Sent http resize request to $url; got ",
	       		$response->status_line(), "\n";
	}

	return $response->is_success();
}

#
# general methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = $self->{description};
}

sub _exif {
	my $self = shift;

	my $path = $self->file();
	my $exif = `exiftags $path`;
	if($exif) {
		return $self->{exif} = $exif;
	} else {
		return undef;
	}
}

# If we did not specify a size, select the size closest to the native size
sub size {
	# TODO deprecate this
	my $self = shift;

	if($self->{size} && $self->{size} ne 'new') {
		return $self->{size};
	}

	return $self->{size} = $self->native();
}

sub _statusquery {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{statusquery} = "status <= $status and not hidden";
}

# This date-based previous/next matching will probably break on very old
# photos, where the database does not record timestamps more precise than days,
# so many photos have the same timestamp; but it will behave as expected for
# everything newer.

sub _prev {
	my $self = shift;

	my $where = "rowkey < " . $self->dbh()->quote($self->rowkey()) .
		" and " . $self->statusquery() .
		" order by rowkey desc limit 1";

	return $self->{prev} = $self->Select($where);
}

sub _next {
	my $self = shift;

	my $where = "rowkey > " . $self->dbh()->quote($self->rowkey()) .
		" and " . $self->statusquery() .
		" order by rowkey asc limit 1";

	return $self->{next} = $self->Select($where);
}

sub _index {
	my $self = shift;

	if($self->{date} == 0) {
		# photos without a date should have the round as their index
		$self->{index} = new Jaeger::Photo::List::Round($self->{round});
	} else {
		# photos with a date should have the date as their index

		# fix the date by GMT offset so we'll get the right day
		$self->{index} = new Jaeger::Photo::List::Date(
			$self->{date} + $self->timezone()->ofst() * 3600
		);
	}

	return $self->{index};
}

sub _url {
	my $self = shift;
	if($self->{uri}) {
		my $baseurl = $Jaeger::Base::BaseURL;
		$baseurl =~ s#/$##;
		return $self->{url} = $baseurl . $self->{uri};
	} else {
		return $self->{url} = $Jaeger::Base::BaseURL .
			"photo.cgi?round=$self->{round}&number=$self->{number}";
	}
}

sub image_url {
	my $self = shift;
	my %params = @_;
	my $size = exists $params{size} ? $params{size} : $self->{size};

	unless($size) {
		foreach my $s (qw(full new)) {
			if($self->{sizes} =~ /$s/) {
				$size = $s;
				last;
			}
		}

		unless($size) {
			die "Photo $self->{round}/$self->{number}: Could not determine size";
		}
	}

	unless($self->{sizes} =~ /$size/) {
		$self->resize($size);
	}

	return "https://storage.googleapis.com/photo.festing.org/"
		. "$self->{round}/$size/$self->{number}.jpg";
}

# If this photo does not have a longitude and latitude set, attempt
# to add them by determining the nearest track points and performing
# a linear regression between them.
#
# This function does not update the database, only this object in memory.
#
# Returns the Jaeger::GPS point added, or undef.
sub geotag {
	my $self = shift;

	# If the photo already has a geotag, return it.
	if(defined($self->{longitude}) && defined($self->{latitude})) {
		my $point = new Jaeger::GPS;
		$point->{longitude} = $self->{longitude};
		$point->{latitude} = $self->{latitude};
		$point->{date} = $self->{date};
		return $point;
	}

	# Try to locate the track points before and after this photo
	my $before = Jaeger::GPS->Select(
		"date <= $self->{date} order by date desc limit 1"
	);
	my @after = Jaeger::GPS->Select(
		"date >= $self->{date} order by date asc limit 2"
	);

	unless(defined $before && @after) {
		# No points before or after this date
		return undef;
	}

	# If the before and after points are equal, use the second after point
	if($before->date() == $after[0]->date()) {
		shift @after;
	}
	my $after = $after[0];

	# Don't geotag if the points are more than 5 km apart, or more than
	# 5 minutes apart, or are exactly the same.
	return undef if $before == $after;
	return undef if ($after->date() - $before->date()) > 300;
	return undef if ($before - $after) > 5;

	# Perform a linear regression between the two points
	my $delta_t = ($after->date() - $before->date());
	my $factor = $self->{date} - $before->date();

	my $latitude = $before->latitude() +
		($after->latitude() - $before->latitude()) * $factor / $delta_t;
	my $longitude = $before->longitude() +
		($after->longitude() - $before->longitude()) *
			$factor / $delta_t;

	$self->{latitude} = $latitude;
	$self->{longitude} = $longitude;

	my $point = new Jaeger::GPS;
	$point->{date} = $self->{date};
	$point->{latitude} = $latitude;
	$point->{longitude} = $longitude;

	return $point;
}

#
# Support for RSS
#

# Returns an RFC 822 date for the publication date (mtime)
sub _pubDate {
	my $self = shift;

	return $self->{pubDate} = POSIX::strftime("%a, %d %b %Y %H:%M:%S %z",
		localtime $self->parsetimestamp($self->mtime()));
}

sub content {
	my $self = shift;

	$self->{size} = $Jaeger::Photo::FeedSize;
	return $self->lf()->photo_rss(
		title => $self->description(),
		date => $self->date_format(),
		image_url => $self->image_url(),
		latitude => $self->{latitude},
		longitude => $self->{longitude},

	);
}

sub _sets {
	my $self = shift;
	my $id = $self->id();
	$self->{sets} = [Jaeger::Photo::Set->Select("join photo_set_map on photo_set.id = photo_set_map.photo_set_id where photo_set_map.photo_id = $id")];
	return $self->{sets};
}

sub update_sets {
	my $self = shift;

	my $success = 1;

	my %new_sets = map {$_, $_} @_;
	my %old_sets = map {$_->id(), $_} @{$self->sets()};

	# Determine the sets that are in %new_sets and not %old_sets. These are
	# the sets that need to be added to the photo.
	my $sql = "insert into photo_set_map values (?, ?)";
	my $sth = $self->Pgdbh()->prepare($sql);
	foreach my $set (keys %new_sets) {
		if(!exists $old_sets{$set}) {
			unless($sth->execute($set, $self->id())) {
				warn "Error adding photo to set $set: $sql\n";
				$success = 0;
			}
		}
	}

	# Determine the sets that are in %old_sets and not %new_sets. These are
	# the sets that need to be deleted from the photo.
	$sql = "delete from photo_set_map where photo_set_id = ? and photo_id = ?";
	$sth = $self->Pgdbh()->prepare($sql);
	foreach my $set (keys %old_sets) {
		if(!exists $new_sets{$set}) {
			unless($sth->execute($set, $self->id())) {
				warn "Error removing photo from set $set: $sql\n";
				$success = 0;
			}
		}
	}

	# Invalidate the cached sets
	delete $self->{sets};

	return $success;
}

sub _xrefs {
	my $self = shift;

	my $subquery = 
		"select changelog_id from photo_xref_map where photo_id = " .
		$self->id();

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{xrefs} = [Jaeger::Changelog->Select(
		"id in ($subquery) and status <= $status")];
}

sub _has_photosphere {
	my $self = shift;

	if($self->{sizes} =~ /photosphere/) {
		return $self->{photosphere} = 1;
	} else {
		return $self->{photosphere} = 0;
	}
}
