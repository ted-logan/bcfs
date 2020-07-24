#!/usr/bin/perl

#
# $Id: changelog.cgi,v 1.4 2003-05-15 00:07:28 jaeger Exp $
#

# changelog.cgi: Displays a changelog, or an index of changelogs
#
# We might want to see changelogs several ways
# id -> displays a changelog by id
# date -> displays all the changelogs corresponding to a specific date
# year -> shows a month thumbnail view by year

use strict;

use lib "$ENV{BCFS}/lib";

use CGI;

use Jaeger::Base;
use Jaeger::Changelog;

my $http_home = '/home/jaeger/web/jaeger.festing.org';

my $q = new CGI;

my $url;

if(my $id = $q->param('id')) {
	# specify specific changelog by id
	$url = "$id.html";

} elsif(my $year = $q->param('browse')) {
	# browse through changelog titles by year
	$url = "$year/";
}

# If anyone is still using the old, pre-2002 url scheme, redirect.
# As of August 2019, there are a few hits per day, virtually all of which
# appear to be crawlers. The perverse part is that these old changelogs are
# restricted-access, so they're not really getting what they expect.
if($url) {
	# redirect accordingly
	print $q->redirect(
		-uri => $Jaeger::Base::BaseURL . "changelog/$url",
		-status => '301 Moved Permanently');
	exit;
}

if(-f $http_home . $ENV{REQUEST_URI}) {
	# This shouldn't happen -- the Apache alias match is supposed to serve
	# static files directly. But in case that's broken, explicitly serve a
	# 500 so it's obvious something's wrong.
	print $q->header(status => 500);
	print "Error serving static content";
	exit;
}

my $user = Jaeger::User->Login();

my $changelog = Jaeger::Changelog::Urimap($ENV{REQUEST_URI}, $user);

if(ref($changelog) eq 'Jaeger::Redirect') {
	# Redirect to a different url.
	if($changelog->{code} == Jaeger::Redirect::MOVED_PERMANENTLY) {
		print $q->redirect(
			-uri => $changelog->{url},
			-status => '301 Moved Permanently');
	} else {
		print $q->redirect($changelog->{url});
	}
	exit;
}

print $q->header(
	-type => 'text/html; charset=UTF-8',
	-status => $changelog->http_status(),
	-cookie => Jaeger::Base::Lookfeel()->{cookies});
print Jaeger::Base::Lookfeel()->main($changelog);
