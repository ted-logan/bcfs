#!/usr/bin/perl

#
# $Id: yoda.cgi,v 1.1 2002-08-26 18:00:43 jaeger Exp $
#

# yoda.cgi: For voyeristic pleasure, display Yoda's gas mileage

use strict;

use lib '/home/jaeger/programming/webpage/lib';
use Jaeger::Lookfeel;
use Jaeger::Yoda;

use CGI;

my $q = new CGI;
my $lf = new Jaeger::Lookfeel;
my $yoda = new Jaeger::Yoda;

if($q->param('go') eq 'yep') {
	# yeah, so this is horribly insecure
	if($q->param('password') eq 'slashdot') {
		# sanity-check and insert the gas-fetching incident
		my %params;

		foreach my $p (@Jaeger::Yoda::Params) {
			$params{$p} = $q->param($p);
		}

		$yoda->insert(%params);
	} else {
		warn "yoda.cgi: Rejected password\n";
	}
}

if($q->param('go') eq 'nope') {
	# show the gas-fetching incident insertion form
	$yoda->{submit} = 1;
}

print "content-type: text/html\n\n";

print $lf->main($yoda);
