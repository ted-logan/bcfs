#!/usr/bin/perl

use strict;

use lib '/home/jaeger/programming/webpage/lib';

# 29 August 2002

use Jaeger::WedGift;
use Jaeger::Lookfeel;

use CGI;

my $q = Jaeger::Base::Query();
my $lf = new Jaeger::Lookfeel;
my $gift = $q->param('id') ?
	Jaeger::WedGift->new_id($q->param('id')) :
	new Jaeger::WedGift;

if($q->param('go') eq 'yep') {
	$gift->insert();

} elsif($q->param('go') eq 'nope') {
	if($q->param('id') == 0) {
		$gift->{id} = '0';
	}
}

print "content-type: text/html\n\n";

if($q->param('print') eq 'yep') {
	print $gift->printer();
} else {
	print $lf->main($gift);
}
