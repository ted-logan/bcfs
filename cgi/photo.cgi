#!/usr/bin/perl

#
# $Id: photo.cgi,v 1.8 2006-12-31 04:24:17 jaeger Exp $
#

# photo.cgi: displays a photo

use strict;

use lib::relative '../lib';

use Jaeger::Photo;
use Jaeger::User;
use Jaeger::Lookfeel;
use Jaeger::Photo::Set;
use Jaeger::Redirect;

my $q = Jaeger::Base::Query();

my $lf = Jaeger::Base::Lookfeel();

my $status = 0;
my $user = Jaeger::User->Login();
if($user) {
	$status = $user->{status};
}

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

if(($status == 30) && ($q->param('submit') eq 'Update')) {
	#my @new_tags = split $q->param('tags');
	my $set_id = $q->param('sets');
	my $set = Jaeger::Photo::Set->new_id($set_id);
	my $status = $q->param('status');
	foreach my $photoid ($q->param('id')) {
		my $photo = Jaeger::Photo->new_id($photoid);
		if($photo) {
			if($set) {
				warn "Adding photo $photo->{round}/$photo->{number} to set $set_id\n";
				$set->add($photo);
			}
			if(defined $status) {
				$photo->{status} = $status;
				$photo->update();
			}

			#warn "Adding tags @new_tags to $photo->{round}/$photo->{number}\n";
		}
	}

	if(my $redirect = $q->param('redirect')) {
		unless($redirect =~ /^http/) {
			$redirect = $Jaeger::Base::BaseURL . '/' . $redirect;
		}
		print $q->redirect($redirect);
		exit;
	}
}

my $uri = $ENV{REQUEST_URI};
$uri =~ s/\?.*$//;

my $page = Jaeger::Photo::Urimap($uri, $user);

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
if(ref($page) eq 'Jaeger::Photo') {
	if($lf->ismobilebrowser()) {
		print $lf->photo_main_mobile($page);
	} else {
		print $lf->photo_main($page);
	}
} else {
	print $lf->photo_list_main($page);
}
