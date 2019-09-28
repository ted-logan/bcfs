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
use Jaeger::Photo::Notfound;
use Jaeger::Photo::Set;
use Jaeger::Photo::Recent;
use Jaeger::Redirect;

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
				$page = new Jaeger::Redirect($page->url(),
					Jaeger::Redirect::MOVED_PERMANENTLY);

			} elsif($user) {
				# The photo exists, but the logged-in user does
				# not have permission to see the photo.
				# Redirect to the photo entry page.
				print $q->redirect("/photo/");
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
			$page = new Jaeger::Photo::Notfound;
		}

	} else {
		# display an index of a round, assuming it exists
		$page = new Jaeger::Photo::List::Round($round);
		if(@{$page->photos()} == 0) {
			# No photos found for this round
			$page = new Jaeger::Photo::Notfound;
		}
	}

} elsif(my $date = $q->param('date')) {
	# display photos on a specific date
	$page = new Jaeger::Photo::List::Date($date);
	$page = new Jaeger::Redirect($page->url(),
		Jaeger::Redirect::MOVED_PERMANENTLY);

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

} elsif(my $year = $q->param('year')) {
	# display a thumbnail for a specific year
	$page = new Jaeger::Redirect("/photo/$year/",
		Jaeger::Redirect::MOVED_PERMANENTLY);

} elsif($ENV{REQUEST_URI} =~ m(^/photo/(\d\d\d\d)$)) {
	$page = new Jaeger::Redirect("/photo/$1/",
		Jaeger::Redirect::MOVED_PERMANENTLY);

} elsif($ENV{REQUEST_URI} =~ m(^/photo/(\d\d\d\d)/$)) {
	# New-style uri: Display a thumbnail for a specific year
	$page = new Jaeger::Photo::Year($1);

} elsif($ENV{REQUEST_URI} =~ m(^/photo/(\d\d\d\d)/(\d\d)/(\d\d)/?$)) {
	# New-style uri: Display photos on a specific date
	my $date = "$1-$2-$3";
	$page = new Jaeger::Photo::List::Date($date);

} elsif($page = Jaeger::Photo->Select(uri => $ENV{REQUEST_URI})) {
	# Cool, found a page
	if($status >= $page->status()) {
		# Good. The photo exists, and the user can see it.
		if($q->param('size')) {
			$page->{size} = $q->param('size');
		} elsif($page->native() > 1600) {
			$page->{size} = '1600x1200';
		}
		$page->resize();

	} elsif($user) {
		# The photo exists, but the logged-in user does not have
		# permission to see the photo.  Redirect to the photo entry
		# page.
		print $q->redirect("/photo/");
		exit;

	} else {
		# The photo exists, but the user is not logged in. Redirect to
		# the login page in case the user has an account.
		my $url = $page->url();
		$url =~ s/([&?])/sprintf "%%%02x", ord $1/ge;
		print $q->redirect("login.cgi?redirect=$url");
		exit;
	}

# TODO also handle redirects

} elsif($ENV{REQUEST_URI} eq '/photo' or $ENV{REQUEST_URI} =~ '/photo.cgi') {
	# Redirect permanently to the new photo url, /photo/
	$page = new Jaeger::Redirect('/photo/',
		Jaeger::Redirect::MOVED_PERMANENTLY);

} elsif($ENV{REQUEST_URI} eq '/photo/') {
	# Display the most recent photos
	$page = new Jaeger::Photo::Recent();

} else {
	# Invalid uri, not found
	$page = new Jaeger::Photo::Notfound;

}

if(ref($page) eq 'Jaeger::Redirect') {
	# Redirect to a different url.
	if($page->{code} == Jaeger::Redirect::MOVED_PERMANENTLY) {
		print $q->redirect(
			-uri => $page->{url},
			-status => '301 Moved Permanently');
	} else {
		print $q->redirect($page->{url});
	}
	exit;
}

print $q->header('text/html; charset=UTF-8', $page->http_status());
if($q->param('slideshow')) {
	print $lf->slideshow($page);
} else {
	if(ref($page) eq 'Jaeger::Photo' or
			ref($page) eq 'Jaeger::Slideshow::Photo') {
		if($lf->ismobilebrowser()) {
			print $lf->photo_main_mobile($page);
		} else {
			print $lf->photo_main($page);
		}
	} else {
		print $lf->photo_list_main($page);
	}
}
