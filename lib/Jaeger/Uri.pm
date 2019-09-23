# Provides a utility function for converting arbitrary titles (eg, for
# changelogs and photos) in utf8 into lowercase 7-bit ascii
package Jaeger::Uri;

use strict;

sub MakeUriFromTitle {
	my $title = shift;

	$title = lc $title;
	$title =~ s/['"]//g;
	$title =~ s/&auml;/ae/g;
	$title =~ s/^[^a-z0-9]*//;
	$title =~ s/[^a-z0-9]*$//;
	$title =~ s/[^a-z0-9]+/-/g;

	return $title;
}

1;
