package		Jaeger::Journal;

#
# $Id: Journal.pm,v 1.4 2002-09-02 05:14:03 jaeger Exp $
#

# Journal-controlling code

# 25 August 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

use Time::Local;

@Jaeger::Journal::ISA = qw(Jaeger::Base);

$Jaeger::Journal::Dir = '/home/jaeger/journal';

# produce html for the latest ten journal entries
# for the moment, this is all this package does

sub Navbar {
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
		my @date_local = @date;
		$date_local[0] -= 1900;
		$date_local[1]--;
		my $time = timelocal(0, 0, 0, reverse @date_local);
		my $weekday = $Jaeger::Base::Weekdays[(localtime $time)[6]];
		my $title = "$weekday $date[2] $Jaeger::Base::Months[$date[1]] $date[0]";

		push @links, $lf->link(url => $url, title => $title);
	}

	return $lf->linkbox(
		url => '/cgi-bin/journal.pl',
		title => 'Journals',
		links => join('', @links)
	);
}

1;
