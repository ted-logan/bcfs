#!/usr/bin/perl

#
# $Id: yoda.cgi,v 1.5 2007-07-08 19:03:00 jaeger Exp $
#

# yoda.cgi: For voyeristic pleasure, display Yoda's gas mileage

use strict;

use lib::relative '../lib';

use Jaeger::Lookfeel;
use Jaeger::Mileage;
use Jaeger::User;

use CGI;

my $q = new CGI;
my $lf = new Jaeger::Lookfeel;
my $user = Jaeger::User->Login();

my $vehicle_id = $q->param('vehicle_id');
unless($vehicle_id) {
	$vehicle_id = 1;
}

my $yoda = new Jaeger::Mileage($vehicle_id);

if($q->param('go') eq 'yep') {
	if($user && $user->status() >= 25) {
		# sanity-check and insert the gas-fetching incident
		my %params;

		foreach my $p (@Jaeger::Mileage::Params) {
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

if($q->param('go') eq 'nope' && $user && $user->status() >= 25) {
	# show the gas-fetching incident insertion form
	$yoda->{submit} = 1;
}

print "content-type: text/html; charset=UTF-8\n\n";

print $lf->main($yoda);
