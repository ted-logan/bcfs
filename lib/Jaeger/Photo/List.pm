package	Jaeger::Photo::List;

# 
# $Id: List.pm,v 1.5 2007-03-01 02:58:00 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Displays a list of photos and thumbnails. Should be derrived to determine
# exactly what this list is of -- a date, or a round

# The derrived class must provide a photo method to return a list reference
# to the photos attached to this list. It must also take care of the prev,
# next, url, and title methods expected by Jaeger::Lookfeel

# created  08 January 2003

use strict;

use Jaeger::Base;

@Jaeger::Photo::List::ISA = qw(Jaeger::Base);

use Jaeger::Photo::List::Date;
use Jaeger::Photo::List::Round;

#
# used by Jaeger::Lookfeel to show this page
#

sub html {
	my $self = shift;

	my @html;

	my $photos = $self->photos();

	foreach my $photo (@$photos) {
		$photo->{size} = $Jaeger::Photo::ThumbnailSize;
		$photo->resize();

		push @html, $self->lf()->photo_list(
			url => $photo->url(),
			thumbnail => "/digitalpics/$photo->{round}/$photo->{size}/$photo->{number}.jpg",
			description => $photo->description(),
			date => $photo->date_format(),
			latitude => $photo->latitude(),
			longitude => $photo->longitude(),
		);
	}

	push @html, <<HTML;
<div style="clear: left;"></div>
HTML

	return join('', @html);
}

sub _xrefs {
	my $self = shift;

	my $photos = $self->photos();
	if(@$photos == 0) {
		return $self->{xrefs} = [];
	}
	my @photo_ids = map {$_->id()} @$photos;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	# Select all of the cross-references for all the photos in the list
	my $where = "id in (select changelog_id from photo_xref_map " .
		"where photo_id in (" . join(', ', @photo_ids) . ")) " .
		"and status <= $status " .
		"order by time_begin";

	return $self->{xrefs} = [Jaeger::Changelog->Select($where)];
}

sub subtitle {
	my $self = shift;
	my $photos = $self->photos();
	return sprintf "%d photo%s",
		scalar(@$photos), (@$photos == 1 ? '' : 's');
}
