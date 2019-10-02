#!/usr/bin/perl

#
# index.cgi: Redirects directly to the newest changelog, replacing the legacy
# splash screen
#

use strict;

use lib "$ENV{BCFS}/lib";

use CGI;

use Jaeger::Base;
use Jaeger::Changelog;

my $latest = Newest Jaeger::Changelog;

my $q = new CGI;

my $useragent = $q->user_agent();
if($useragent =~ /googlebot/i) {
	# If the user agent is Googlebot, redirect to the current year's index
	# page
	print $q->redirect($latest->index()->url());
} else {
	# Otherwise redirect everyone else to the latest changelog
	print $q->redirect($latest->url());
}
