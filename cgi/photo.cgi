#!/usr/bin/perl

#
# $Id: photo.cgi,v 1.5 2006-06-22 03:49:22 jaeger Exp $
#

# photo.cgi: displays a photo

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;
use Jaeger::Lookfeel;

my $q = Jaeger::Base::Query();

my $lf = Jaeger::Base::Lookfeel();

my $page;

if(my $round = $q->param('round')) {
	if(my $number = $q->param('number')) {
		# display a specific photo, assuming it exists
		$page = Jaeger::Photo->Select(
			round => $round,
			number => $number
		);

		if($page) {
			# Good. The photo exists.
			$page->{size} = $q->param('size');

		} else {
			# the photo doesn't exist
		}

	} else {
		# display an index of a round, assuming it exists
		$page = new Jaeger::Photo::List::Round($round);
	}

} elsif(my $date = $q->param('date')) {
	# display photos on a specific date
	$page = new Jaeger::Photo::List::Date($date);

} else {
	# display a thumbnail for a year, or the current year
	$page = new Jaeger::Photo::Year($q->param('year'));

}

print "content-type: text/html; charset=UTF-8\n\n";
if($q->param('slideshow')) {
	print $lf->slideshow($page);
} else {
	if(ref($page) eq 'Jaeger::Photo') {
		print $lf->photo_main($page);
	} else {
		print $lf->main($page);
	}
}
