#!/usr/bin/perl

#
# $Id: photo.cgi,v 1.8 2006-12-31 04:24:17 jaeger Exp $
#

# photo.cgi: displays a photo

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;
use Jaeger::Slideshow;
use Jaeger::Lookfeel;
use Jaeger::Photo::Set;

my $q = Jaeger::Base::Query();

my $lf = Jaeger::Base::Lookfeel();

my $page;

if(my $photo_id = $q->param('photo_id')) {
	my $slideshow_id = $q->param('slideshow_id');

	my $photo = Jaeger::Photo->new_id($photo_id);
	my $slideshow = Jaeger::Slideshow->new_id($slideshow_id);

	if($photo && $slideshow) {
		$slideshow->add_photo($photo, $q->param('index'),
			$q->param('description'));

		print $q->redirect($photo->url());
		exit;
	} else {
		die "Could not find photo by id $photo_id or slideshow by id $slideshow_id\n";
	}
}

if(my $round = $q->param('round')) {
	if(my $number = $q->param('number')) {
		# display a specific photo, assuming it exists
		$page = Jaeger::Photo->Select(
			round => $round,
			number => $number
		);

		if($page) {
			# Good. The photo exists.
			if($q->param('size')) {
				$page->{size} = $q->param('size');
			} elsif($page->native() > 800) {
				$page->{size} = '800x600';
			}
			$page->resize();

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

} elsif(my $slideshow = $q->param('slideshow_id')) {
	# Show a specific slide show
	my $slideshow = Jaeger::Slideshow->new_id($slideshow);
	if(defined($slideshow) && (my $index = $q->param('index'))) {
		$page = $slideshow->photo_hash()->{$index};
	} else {
		$page = $slideshow;
	}

} elsif(my $set = $q->param('set')) {
	$page = Jaeger::Photo::Set->new_id($set);

} else {
	# display a thumbnail for a year, or the current year
	$page = new Jaeger::Photo::Year($q->param('year'));

}

print "content-type: text/html; charset=UTF-8\n\n";
if($q->param('slideshow')) {
	print $lf->slideshow($page);
} else {
	if(ref($page) eq 'Jaeger::Photo' or
			ref($page) eq 'Jaeger::Slideshow::Photo') {
		print $lf->photo_main($page);
	} else {
		print $lf->main($page);
	}
}
