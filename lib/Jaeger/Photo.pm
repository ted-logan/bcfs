package	Jaeger::Photo;

# 
# $Id: Photo.pm,v 1.7 2007-03-01 02:58:00 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Provides a handy-dandy interface for my vast digital photo collection

# created  05 January 2003

use strict;

use Jaeger::Base;

@Jaeger::Photo::ISA = qw(Jaeger::Base);

use Carp;

use Jaeger::Location;
use Jaeger::Timezone;

use Jaeger::Photo::List;
use Jaeger::Photo::Year;

use Image::Magick;

sub table {
	return 'photo';
}

$Jaeger::Photo::Dir = '/home/jaeger/graphics/photos/dc';

@Jaeger::Photo::Sizes = qw(640x480 800x600 1024x768 1280x960 1600x1200 2048x1536 3000x2000);

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

	$self->SUPER::update();
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
		my $file = "$Jaeger::Photo::Dir/$self->{round}/$self->{size}/$self->{number}.jpg";
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

	return $self->{thumbnail} = "$Jaeger::Photo::Dir/$self->{round}/thumbnail/$self->{number}.jpg";
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
	my $self = shift;

	if($self->{size}) {
		return $self->{size};
	}

	if($self->file_crop()) {
		return $self->{size} = 'new';
	}

	if($self->file_raw()) {
		return $self->{size} = 'raw';
	}

	# The photo doesn't seem to exist. This could be bad.
	return undef;
}

# Return the photo size closest to the actual size, in 640x480
sub _native {
	my $self = shift;

	my $img = new Image::Magick;
	$img->Read($self->file_crop() ? $self->file_crop() : $self->file_raw());

	my ($width, $height) = $img->Get('width', 'height');

	my $lastsize;

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

# Make sure the photo exists for the desired size
sub resize {
	my $self = shift;

	if($self->size()) {
		my $file = "$Jaeger::Photo::Dir/$self->{round}/$self->{size}/$self->{number}.jpg";

		unless(-f $file) {
			system "$ENV{BCFS}/bin/resize_photo.pl $self->{round} $self->{number} $self->{size}";
		}
	}
}

#
# general methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = "Photo $self->{round}/$self->{number}: " .
		$self->{description};
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
	my $self = shift;

	if($self->{size} && $self->{size} ne 'new') {
		return $self->{size};
	}

	return $self->{size} = $self->native();
}

sub _sizelinks {
	my $self = shift;

	my @html;

	my $url = $self->url();

	foreach my $size (@Jaeger::Photo::Sizes) {
		if($size eq $self->size()) {
			push @html, $size;
		} elsif($size <= $self->native()) {
			push @html, qq'<a href="$url&size=$size">$size</a>';
		}
	}

	return join ' | ', @html;
}

# returns the html for this object
sub html {
	my $self = shift;

	return $self->lf()->photo(
		id => $self->{id},
		title => $self->{description},
#		exif => $self->exif(),
		date => $self->date_format(),
		round => $self->{round},
		size => $self->size(),
		sizelinks => $self->sizelinks(),
		number => $self->{number},
		latitude => $self->{latitude},
		longitude => $self->{longitude},
	);
}

# Always use round and number to select the previous and next photos.
# I'm fairly confident this isn't the number one best way to do this, but
# my attempt at writing another query failed miserabally. This at least works.

sub _prev {
	my $self = shift;

	$self->{prev} = $self->Select("((round = '$self->{round}' and number < '$self->{number}') or (round < '$self->{round}')) and not hidden order by round desc, number desc limit 1");

	return $self->{prev};
}

sub _next {
	my $self = shift;

	$self->{next} = $self->Select("((round = '$self->{round}' and number > '$self->{number}') or (round > '$self->{round}')) and not hidden order by round, number limit 1");

	return $self->{next};
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

	return $self->{url} =
		"photo.cgi?round=$self->{round}&number=$self->{number}";
}
