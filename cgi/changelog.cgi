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

use CGI;

my $q = new CGI;

my $url;

if(my $id = $q->param('id')) {
	# specify specific changelog by id
	$url = "$id.html";

} elsif(my $year = $q->param('browse')) {
	# browse through changelog titles by year
	$url = "$year/";
}

# redirect accordingly
print $q->redirect("http://jaeger.festing.org/changelog/$url");
