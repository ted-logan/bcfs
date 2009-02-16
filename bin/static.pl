#!/usr/bin/perl

#
# $Id: static.pl,v 1.2 2003-08-25 03:20:44 jaeger Exp $
#

# Statically exports changelogs into html files

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::Lookfeel;

my $lf = new Jaeger::Lookfeel;

my $dir = "$ENV{BCFS}/html";

my @changelogs = Jaeger::Changelog->Select();

foreach my $changelog (@changelogs) {
	print "$changelog->{id}: $changelog->{time_begin} $changelog->{title}\n";

	open F, ">$dir/$changelog->{id}.html"
		or die "Can't write: $!\n";

	print F $lf->main($changelog);

	close F;
}

exit;

my $lastid = $changelogs[-1]->{id};

# output the static index page
open F, ">$dir/index.html"
	or die "Can't write: $!\n";
print F $lf->index(lastid => $lastid);
close F;

# output the cgi redirects
open F, ">$dir/content.cgi"
	or die "Can't write: $!\n";
print F $lf->redirect(lastid => $lastid);
close F;

open F, ">$dir/changelog.cgi"
	or die "Can't write: $!\n";
print F $lf->redirect(lastid => $lastid);
close F;

chmod 0755, "$dir/content.cgi", "$dir/changelog.cgi";
