#!/usr/bin/perl

#
# $Id: cs2.pl,v 1.2 2003-08-25 03:21:11 jaeger Exp $
#
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Updates jaegerfesting and Jaeger's Journals into Content Solutions 2.0

use strict;

use lib '/home/jaeger/programming/webpage/lib';
use lib '/home/jaeger/programming/cs2';

# jaegerfesting modules
use Jaeger::Changelog;
use Jaeger::Journal;

# Content Solutions 2.0 modules
use CS2::Site;
use CS2::Update qw(update);

#
# update changelogs
#
{
	my $site_id = 1;
	my $password = 'slashdot';

	my $site = CS2::Site->new_id($site_id);
	my $max = $site->max_native_id();

	my @changelogs = Jaeger::Changelog->Select("id > $max");

	foreach my $changelog (@changelogs) {
		my $headline = new CS2::Headline;

		$headline->{site_id} = $site_id;
		$headline->{native_id} = $changelog->id();
		$headline->{timestamp} = $changelog->time_end();
		$headline->{title} = $changelog->title();
		$headline->{url} = 'http://jaeger.festing.org' .
			$changelog->url();

		$headline->update();
	}

	if(@changelogs) {
		update($site_id, $password);
	}
}

#
# update journals
#
{
	my $site_id = 6;
	my $password = 'slashdot';

	my $site = CS2::Site->new_id($site_id);
	my $max = $site->max_native_id();

	# convert the max id back into a date
	my $date = $max;
	$date =~ s/(\d\d\d\d)(\d\d)(\d\d)/$1-$2-$3/;

	my @journals = Jaeger::Journal->Select("entrydate > '$max'");

	foreach my $journal (@journals) {
		my $headline = new CS2::Headline;

		my $native_id = $journal->entrydate();
		$native_id =~ s/-//g;

		$headline->{site_id} = $site_id;
		$headline->{native_id} = $native_id;
		$headline->{timestamp} = $journal->time_end();
		$headline->{title} = $journal->title();
		$headline->{url} = 'http://jaeger.festing.org' .
			$journal->url();

		$headline->update();
	}

	if(@journals) {
		update($site_id, $password);
	}
}
