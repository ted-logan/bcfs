package	Jaeger::Slideshow;

# 
# $Id: Slideshow.pm,v 1.1 2006-12-31 04:24:18 jaeger Exp $
#
# Copyright (c) 2006 Ted Logan (jaeger@festing.org)

# Wraps the slideshow table

# created 30 December 2006

use strict;

use Carp;

use Data::Dumper;

use Jaeger::Base;

use Jaeger::Photo::List;
use Jaeger::Slideshow::Photo;

@Jaeger::Slideshow::ISA = qw(Jaeger::Photo::List);

sub table {
	return 'slideshow';
}

sub update {
	my $self = shift;

	unless(defined $self->{title}) {
		carp "Jaeger::Slideshow->update(): title is not defined";
		return undef;
	}

	return $self->SUPER::update();
}

# Returns a hash reference containing the slideshow photos, indexed by index.
# Jaeger::Slideshow::Photo objects
sub _photo_hash {
	my $self = shift;

	my @photos = Jaeger::Slideshow::Photo->Select(
		slideshow_id => $self->id()
	);

	return $self->{photo_hash} =
		{ map {$_->slideshow_index(), $_} @photos };
}

# Returns a reference to an array containing the photos, in order.
sub _photos {
	my $self = shift;

	my @photos = sort {$a->slideshow_index() <=> $b->slideshow_index()}
		values %{$self->photo_hash()};

	return $self->{photos} = \@photos;
}

sub add_photo {
	my $self = shift;

	my $photo = shift;
	my $index = shift;
	my $description = shift;

	my $photos = $self->photo_hash();
	if($index) {
		if($photos->{$index}) {
			# Renumber photos so we can use the new index
		}
	} else {
		# Pick an index one greater than the largest in the database
		my @indices = reverse sort {$a <=> $b} keys %$photos;
		$index = $indices[0] + 1;
	}

	my $entry = new Jaeger::Slideshow::Photo;
	$entry->{slideshow} = $self;
	$entry->{photo} = $photo;
	$entry->{slideshow_index} = $index;
	$entry->{description} = $description;

	$entry->update();
}

sub title {
	my $self = shift;

	return "Slideshow: " . $self->{title};
}

sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL .
		'photo.cgi?slideshow_id=' . $self->id();
}
