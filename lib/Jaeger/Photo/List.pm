package	Jaeger::Photo::List;

# 
# $Id: List.pm,v 1.1 2003-01-10 06:57:26 jaeger Exp $
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
use Jaeger::Photo::List::Search;

#
# used by Jaeger::Lookfeel to show this page
#

sub html {
	my $self = shift;

	my @html;

	push @html, $self->lf()->changelog_title(title => $self->title());

	my $photos = $self->photos();

	push @html, "<tr><td>", scalar(@$photos), " photos</td></tr>\n";

	foreach my $photo (@$photos) {
		push @html, $self->lf()->photo_list(
			url => $photo->url(),
			thumbnail => "/digitalpics/$photo->{round}/thumbnail/$photo->{number}.jpg",
			description => $photo->description(),
			date => $photo->date_format()
		);
	}

	return join('', @html);
}
