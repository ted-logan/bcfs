package		Jaeger::Journal;

#
# $Id: Journal.pm,v 1.1 2002-08-26 06:06:15 jaeger Exp $
#

# Journal-controlling code

# 25 August 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

use Time::Local;

@Jaeger::Journal::ISA = qw(Jaeger::Base);

@Jaeger::Journal::Months = qw(blah January February March April May June July August September October November December);
@Jaeger::Journal::Weekdays = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

$Jaeger::Journal::Dir = '/home/jaeger/journal';

# produce html for the latest ten journal entries
# for the moment, this is all this package does

sub Navbar {
	my $dbh = $Jaeger::Base::Pgdbh;
	my $lf = new Jaeger::Lookfeel;

	my @links;

	opendir JOURNALDIR, $Jaeger::Journal::Dir
		or return undef;
	my @entries = reverse sort grep /^\d\d\d\d\.\d\d\.\d\d\.html$/,
		readdir JOURNALDIR;
	closedir JOURNALDIR;

	foreach my $entry (@entries[0 .. 9]) {
		my $url = "/cgi-bin/journal.pl?$entry";
		$url =~ s/\.html//;

		my @date = (split /\./, $entry)[0 .. 2];
		my $time = timelocal(0, 0, 0, reverse @date);
		my $weekday = $Jaeger::Journal::Weekdays[(localtime $time)[6]];
		my $title = "$weekday $date[2] $Jaeger::Journal::Months[$date[1]] $date[0]";

		push @links, $lf->link(url => $url, title => $title);
	}

	return $lf->linkbox(
		url => '/cgi-bin/journal.pl',
		title => 'Journals',
		links => join('', @links)
	);
}

1;
