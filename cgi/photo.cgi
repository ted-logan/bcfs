#!/usr/bin/perl

#
# $Id: photo.cgi,v 1.8 2006-12-31 04:24:17 jaeger Exp $
#

# photo.cgi: displays a photo

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;
use Jaeger::User;
use Jaeger::Slideshow;
use Jaeger::Lookfeel;
use Jaeger::Photo::Set;

my $q = Jaeger::Base::Query();

my $lf = Jaeger::Base::Lookfeel();

my $status = 0;
my $user = Jaeger::User->Login();
if($user) {
	$status = $user->{status};
}

my $page;

if(($status == 30) &&
	($q->param('submit') eq 'Save') &&
	(my $photo = Jaeger::Photo->new_id($q->param('id')))) {

	warn "About to edit photo $photo->{round}/$photo->{number} (id=$photo->{id})\n";

	$photo->{description} = $q->param('title');
	$photo->{status} = $q->param('status');
	$photo->{timezone_id} = $q->param('phototimezone');
	# TODO handle camera time zone
	# TODO update mtime?

	$photo->update_sets($q->param('sets'));
	$photo->update();
}

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
			if($status >= $page->status()) {
				# Good. The photo exists, and the user can see
				# it.
				if($q->param('size')) {
					$page->{size} = $q->param('size');
				} elsif($page->native() > 1024) {
					$page->{size} = '1024x768';
				}
				$page->resize();

			} elsif($user) {
				# The photo exists, but the logged-in user does
				# not have permission to see the photo.
				# Redirect to the photo entry page.
				print $q->redirect("photo.cgi");
				exit;

			} else {
				# The photo exists, but the user is not logged
				# in. Redirect to the login page in case the
				# user has an account.
				my $url = $page->url();
				$url =~ s/([&?])/sprintf "%%%02x", ord $1/ge;
				print $q->redirect("login.cgi?redirect=$url");
				exit;
			}

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
		print $lf->photo_list_main($page);
	}
}
