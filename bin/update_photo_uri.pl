#!/usr/bin/perl

# Update the photo-changelog cross-references for all changelogs in the
# database.

use strict;

use POSIX;
use Encode qw(decode);

use lib::relative '../lib';

use Jaeger::Photo;
use Jaeger::Uri;

binmode STDOUT, ':utf8';

my %all_uris;

my $iter = Jaeger::Photo->Prepare("not hidden order by date, round, number");
while(my $photo = $iter->next()) {
	$photo->{uri} = $photo->create_uri(\%all_uris);

	print "$photo->{round}/$photo->{number}: ", $photo->date_format(), "  ",
		decode("utf-8", $photo->description()), "\n";
	print "\t$photo->{uri}\n\n";

	$photo->update();
}
