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
# (There are a *bunch* of hits in my weblog from this url scheme, which all
# appear to be crawlers. Perhaps I should use a 301-redirect instead of a 302.)
if($url) {
	# redirect accordingly
	print $q->redirect($Jaeger::Base::BaseURL . "/changelog/$url");
	exit;
}

my $user = Jaeger::User->Login();

my $changelog = Jaeger::Changelog::Urimap($ENV{REQUEST_URI}, $user);

unless(ref $changelog) {
	print $q->redirect($changelog);
	exit;
}

print $q->header('text/html; charset=UTF-8');
print Jaeger::Base::Lookfeel()->main($changelog);
