package	Jaeger::Slideshow::Photo;

# 
# $Id: Photo.pm,v 1.1 2006-12-31 04:24:18 jaeger Exp $
#
# Copyright (c) 2006 Ted Logan (jaeger@festing.org)

# Wraps the slideshow_photo_map table

# created 30 December 2006

use strict;

use Carp;

use Jaeger::Base;

use Jaeger::Photo;
use Jaeger::Slideshow;

@Jaeger::Slideshow::Photo::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new(@_);

	if($self->{id}) {
		# This object exists thanks to the database. Fill the relevant
		# parameters
		$self->{round} = $self->photo()->round();
		$self->{number} = $self->photo()->number();
	}

	return $self;
}

sub table {
	return 'slideshow_photo_map';
}

sub update {
	my $self = shift;

	unless($self->{slideshow_id}) {
		if($self->{slideshow}) {
			$self->{slideshow_id} = $self->{slideshow}->id();
		} else {
			carp "Jaeger::Slideshow::Photo->update(): slideshow is not defined";
			return undef;
		}
	}

	unless(defined $self->{slideshow_index}) {
		carp "Jaeger::Slideshow::Photo->update(): slideshow_index is not defined";
		return undef;
	}

	unless($self->{photo_id}) {
		if($self->{photo}) {
			$self->{photo_id} = $self->{photo}->id();
		} else {
			carp "Jaeger::Slideshow::Photo->update(): photo is not defined";
			return undef;
		}
	}

	return $self->SUPER::update();
}

sub _slideshow {
	my $self = shift;

	return $self->{slideshow} =
		Jaeger::Slideshow->new_id($self->{slideshow_id});
}

sub _photo {
	my $self = shift;

	return $self->{photo} = Jaeger::Photo->new_id($self->{photo_id});
}

sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL .
		'photo.cgi?slideshow_id=' . $self->{slideshow_id} .
		'&index=' . $self->{slideshow_index};
}

sub _date_format {
	my $self = shift;

	return $self->{date_format} = $self->photo()->date_format();
}

sub title {
	my $self = shift;

	return $self->slideshow()->title() . ': ' .
		$self->photo()->description();
}

sub html {
	my $self = shift;

	$self->photo()->{size} = '800x600';
	$self->photo()->resize();

	return $self->photo()->html() . "<p>$self->{description}</p>";
}

sub _prev {
	my $self = shift;

	$self->{prev} = $self->Select("slideshow_id = $self->{slideshow_id} and slideshow_index < $self->{slideshow_index} limit 1");

	return $self->{prev};
}

sub _next {
	my $self = shift;

	$self->{next} = $self->Select("slideshow_id = $self->{slideshow_id} and slideshow_index > $self->{slideshow_index} limit 1");

	return $self->{next};
}

sub _index {
	my $self = shift;

	return $self->slideshow();
}
