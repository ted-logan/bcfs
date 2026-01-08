#!/usr/bin/perl

# Update the photo-changelog cross-references for all changelogs in the
# database.

use strict;

use lib::relative '../lib';

use Jaeger::Changelog;

my $iter = Jaeger::Changelog->Prepare();
while(my $changelog = $iter->next()) {
	$changelog->update_photo_xref();
}
