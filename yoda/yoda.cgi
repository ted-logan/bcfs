#!/usr/bin/perl

#
# $Id: yoda.cgi,v 1.3 2003-10-01 01:27:15 jaeger Exp $
#

# yoda.cgi: For voyeristic pleasure, display Yoda's gas mileage

use strict;

use lib '/home/jaeger/programming/webpage/lib';
use Jaeger::Lookfeel;
use Jaeger::Yoda;
use Jaeger::User;

use CGI;

my $q = new CGI;
my $lf = new Jaeger::Lookfeel;
my $yoda = new Jaeger::Yoda;
my $user = Jaeger::User->Login();

if($q->param('go') eq 'yep') {
	if($user && $user->login() eq 'jaeger') {
		# sanity-check and insert the gas-fetching incident
		my %params;

		foreach my $p (@Jaeger::Yoda::Params) {
			$params{$p} = $q->param($p);
		}

		if($q->param('valid')) {
			$params{valid} = 'true';
		} else {
			$params{valid} = 'false';
		}

		$yoda->insert(%params);
	}
}

if($q->param('go') eq 'nope' && $user && $user->login() eq 'jaeger') {
	# show the gas-fetching incident insertion form
	$yoda->{submit} = 1;
}

print "content-type: text/html\n\n";

print $lf->main($yoda);
