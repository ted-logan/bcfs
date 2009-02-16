#!/usr/bin/perl

#
# $Id: content.cgi,v 1.4 2004-11-12 23:35:57 jaeger Exp $
#

# displays a page of static content, or redirects to a changelog if we're being
# called using the old method

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::Content;
use Jaeger::Lookfeel;

use CGI;

my $q = new CGI;

my $content = Jaeger::Content->Select(label => scalar $q->param('page'));
if($content) {
	# show some content
	my $lf = new Jaeger::Lookfeel;

	print "content-type: text/html; charset=UTF-8\n\n";
	print $lf->main($content);

} else {
	# redirect to my changelogs

	my $url = $Jaeger::Base::BaseURL . '/changelog/';

	if($q->param('what') eq 'article') {
		my $id_old = $q->param('id');
		if(my $changelog = Jaeger::Changelog->old_id($id_old)) {
			$url = $changelog->url();
		}
	} elsif($q->param('what') eq 'content') {
		$url = $Jaeger::Base::BaseURL . '/content.cgi?page=' .
			$q->param('label');
	}

	print $q->redirect($url);
}
