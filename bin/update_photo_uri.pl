#!/usr/bin/perl

# Update the photo-changelog cross-references for all changelogs in the
# database.

use strict;

use POSIX;
use Encode qw(encode decode);

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;
use Jaeger::Uri;

binmode STDOUT, ':utf8';

my %all_uris;

my $iter = Jaeger::Photo->Prepare("not hidden order by date, round, number");
while(my $photo = $iter->next()) {
	my $date;
	if($photo->{date} != 0) {
		$date = POSIX::strftime("%Y/%m/%d/",
			gmtime($photo->{date} +
				$photo->timezone()->ofst() * 3600));
	}

	my $this_photo_is_special = 0;

	my $title = decode("utf-8", $photo->description());
	unless($title) {
		$title = "untitled";
	}
	foreach my $char (split //, $title) {
		if(ord($char) > 127) {
			#print "Non-ascii code point $char (", ord($char), ")\n";
			$this_photo_is_special = 1;
		}
	}

	unless($this_photo_is_special) {
	#	next;
	}

	$title = Jaeger::Uri::MakeUriFromTitle($title);

	my $uri;
	my $count = 1;
	do {
		$uri = "$date$title";
		if($count > 1) {
			$uri .= '-' . $count;
		}
		$count++;
	} while(exists $all_uris{$uri});

	print "$photo->{round}/$photo->{number}: ", $photo->date_format(), "  ",
		decode("utf-8", $photo->description()), "\n";
	print "\t$uri\n\n";

	$all_uris{$uri}++;
}
