package	Jaeger::Photo::Search;

# 
# $Id: Search.pm,v 1.2 2006-06-22 03:49:05 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Displays a list of photos and thumbnails according to a search
# Now exists without the help of Jaeger::Photo::List that Jaeger::Search exists

# created  08 January 2003

use strict;

use Jaeger::Search::Searchable;
use Jaeger::Photo;
use Jaeger::User;

@Jaeger::Photo::Search::ISA = qw(Jaeger::Search::Searchable);

# returns a list of photos for this search, to be used by
# Jaeger::Search::Searchable
sub _content {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	# select the photos
	my @photos = Jaeger::Photo->Select(
		$self->{search}->like('description') . 
		" and status <= $status and not hidden " .
		'order by date desc'
	);

	# rank the photos
	foreach my $photo (@photos) {
		$photo->{rank} = $self->{search}->rank($photo->{description});
	}

	return @photos;
}

sub what {
	return 'photos';
}

#
# methods used by Jaeger::Search::Searchable to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = 'Photo Search Results';
}

# this sub was copied and pasted from Jaeger::Photo::List
sub _html {
	my $self = shift;

	my @html;

	my $photos = $self->content();

	foreach my $photo (@$photos) {
		next unless $photo;

		$photo->{size} = "256x192";
		$photo->resize();

		push @html, $self->lf()->photo_list(
			url => $photo->url(),
			thumbnail => $photo->image_url(),
			description => $photo->description(),
			date => $photo->date_format(),
			latitude => $photo->latitude(),
			longitude => $photo->longitude(),
		);
	}

	return join('', @html);
}
