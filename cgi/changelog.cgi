#!/usr/bin/perl

#
# $Id: changelog.cgi,v 1.2 2002-09-22 00:03:26 jaeger Exp $
#

# changelog.cgi: Displays a changelog, or an index of changelogs
#
# We might want to see changelogs several ways
# id -> displays a changelog by id
# date -> displays all the changelogs corresponding to a specific date
# year -> shows a month thumbnail view by year

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Changelog;
use Jaeger::Lookfeel;

use CGI;

my $q = new CGI;

my $lf = new Jaeger::Lookfeel;

my $changelog;

if(my $id = $q->param('id')) {
	# specify specific changelog by id
	$changelog = new Jaeger::Changelog($id);
	unless($changelog) {
		$changelog = new Jaeger::Changelog;
		$changelog->{title} = 'No changelog';
		$changelog->{content} = 'No changelog was found with the given id';
	}

} elsif(my $year = $q->param('browse')) {
	# browse through changelog titles by year
	$changelog = Jaeger::Changelog->browse($year);

=for later
} elsif(my $date = $q->param('date')) {
	# show all changelogs on a date

} elsif(my $year = $q->param('year')) {
	# link to all changelogs in a year

=cut
} else {
	# show the most recent changelog
	$changelog = newest Jaeger::Changelog;
}

# display the changelog
print "content-type: text/html\n\n";
print $lf->main($changelog);
