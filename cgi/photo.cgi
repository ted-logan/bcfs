#!/usr/bin/perl

#
# $Id: photo.cgi,v 1.2 2003-01-26 12:41:25 jaeger Exp $
#

# photo.cgi: displays a photo

use strict;

use lib '/home/jaeger/programming/webpage/lib';

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

print "content-type: text/html\n\n";
print $lf->main($page);
