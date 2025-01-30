# Provides a utility function for converting arbitrary titles (eg, for
# changelogs and photos) in utf8 into lowercase 7-bit ascii
package Jaeger::Uri;

use strict;
use utf8;

use Carp;
use Encode qw(encode);

sub MakeUriFromTitle {
	my $title = shift;

	$title = encode('ascii', $title, \&latintoascii);
	$title = lc $title;
	$title =~ s/['"]//g;
	$title =~ s/&auml;/ae/g;
	$title =~ s/&(\w)\w+;/\1/g;
	$title =~ s/D&D/dnd/gi;
	$title =~ s/^[^a-z0-9]*//;
	$title =~ s/[^a-z0-9]*$//;
	$title =~ s/[^a-z0-9]+/-/g;

	return $title;
}

# Implement a crude latin1-to-ascii conversion. Implement the non-ascii code
# points actually present in my photo database, ignoring the others.
sub latintoascii {
	my $char = chr shift;

	my %mapping = (
		'Ø' => 'O',
		'ä' => 'ae',
		'í' => 'i',
		'ö' => 'o',
		'ø' => 'o',
		'ā' => 'a',
		'ñ' => 'n',
		'ʻ' => '',
		'ū' => 'u',
	);

	if(exists $mapping{$char}) {
		return $mapping{$char};
	} else {
		carp "Unrecogonized non-ascii code point $char (", ord($char),
			")";
		return '?';
	}
}

1;
