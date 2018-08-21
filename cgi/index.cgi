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

print $q->redirect($latest->url());
