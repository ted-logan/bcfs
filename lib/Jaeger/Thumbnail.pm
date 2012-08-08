package Jaeger::Thumbnail;

#
# $Id: Thumbnail.pm,v 1.3 2006-02-18 04:20:04 jaeger Exp $
#

# Generates a month thumbnail, or an array of month thumbnails for a year,
# with links to input data

# Originally written for journal.pl sometime in April 2000
# Ported to jaegerfesting 09 January 2002

use strict;

use Exporter;

@Jaeger::Thumbnail::ISA = qw(Exporter);
@Jaeger::Thumbnail::EXPORT_OK = qw(month_thumbnail year_thumbnail);

use Time::Local;

@Jaeger::Thumbnail::Months = qw(January February March April May June July August September October November December);

sub month_thumbnail {
	my ($month, $year, $data) = @_;

	my @html;

	push @html, "<h2>$Jaeger::Thumbnail::Months[$month - 1] $year</h2>\n";
	push @html, "<pre>";
	push @html, " S  M Tu  W Th  F  S\n";

	my $date = timelocal(0, 0, 12, 1, $month - 1, $year - 1900);
	my $weekday = (localtime($date))[6];
	my $day = 1;
	my $mon = $month - 1;
	push @html, '   ' x $weekday;
	while($mon == $month - 1) {
		my $daytext = sprintf "%2i", $day;
		my $datename = sprintf("%04d-%02d-%02d", $year, $month, $day);
		if($data->{$datename}) {
			$daytext =~ s/(\d+)/<a href="$data->{$datename}">$1<\/a>/;
		}
		push @html, "$daytext ";

		$date += 86400;
		($day, $weekday, $mon) = (localtime($date))[3, 6, 4];
		if($weekday == 0) {
			push @html, "\n";
		}
	}

	push @html, "</pre>\n";

	return join('', @html);
}

sub year_thumbnail {
	my ($year, $data) = @_;

	my @html;

	push @html, "<h1>$year</h1>\n";
	for(my $month = 1; $month < 13; $month++) {
		my $style = "padding-right: 1em; float: left;";
		if(($month % 3) == 1) {
			$style .= " clear: left;";
		}
		push @html, "<div style=\"$style\">\n";
		push @html, month_thumbnail($month, $year, $data);
		push @html, "</div>\n";
	}

	push @html, qq'<div style="clear: left;"></div>\n';

	return join('', @html);
}

1;
