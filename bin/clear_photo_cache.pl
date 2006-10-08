#!/usr/bin/perl

#
# $Id: clear_photo_cache.pl,v 1.1 2006-10-08 19:32:14 jaeger Exp $
#

# To conserve disk space, clear cached photos that have not been accessed
# recently.

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";
use Jaeger::Photo;

use File::Find;

# Look for files that have not been accessed in two weeks.
my $mindate = time() - 14*24*3600;

find(sub {
	return unless $File::Find::name =~ m#/\d+x\d+/[a-zA-Z0-9_-]+\.jpg#;
	return unless (stat $File::Find::name)[8] < $mindate;
	unlink $File::Find::name
		or warn "$File::Find::name: $!\n";
}, $Jaeger::Photo::Dir);
