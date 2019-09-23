#!/usr/bin/perl

use strict;
use utf8;

# Test case for Jaeger::Uri

use Test::More;

# Note: This script is intended to be run from the 'test' directory, since I
# can't figure out a good way to get Perl to include the correct library path 
use lib "../..";

use Jaeger::Uri;

is(Jaeger::Uri::MakeUriFromTitle('Hello World'), 'hello-world');
is(Jaeger::Uri::MakeUriFromTitle('Hello World!'), 'hello-world');
is(Jaeger::Uri::MakeUriFromTitle('123 text 456'), '123-text-456');
is(Jaeger::Uri::MakeUriFromTitle("apostrophe's removed"),
	'apostrophes-removed');
is(Jaeger::Uri::MakeUriFromTitle('Everything is fine (really)'),
	'everything-is-fine-really');
is(Jaeger::Uri::MakeUriFromTitle('    whitespace ----'), 'whitespace');
is(Jaeger::Uri::MakeUriFromTitle('J&auml;ger'), 'jaeger');
is(Jaeger::Uri::MakeUriFromTitle('Quotes "go away"'), 'quotes-go-away');

# Other html entities
is(Jaeger::Uri::MakeUriFromTitle('Resum&eacute;'), 'resume');

# D&D
is(Jaeger::Uri::MakeUriFromTitle('People play D&D'), 'people-play-dnd');

# Unicode code points
is(Jaeger::Uri::MakeUriFromTitle('Dessert at Häagen-Dazs in Hong Kong'),
	'dessert-at-haeagen-dazs-in-hong-kong');
is(Jaeger::Uri::MakeUriFromTitle(
	'Diagonal elevator at Sörnäinen metro station'),
	'diagonal-elevator-at-sornaeinen-metro-station');
is(Jaeger::Uri::MakeUriFromTitle('Øresund Straight under an A320 wing'),
	'oresund-straight-under-an-a320-wing');
is(Jaeger::Uri::MakeUriFromTitle('Spire on Børsen'), 'spire-on-borsen');
is(Jaeger::Uri::MakeUriFromTitle('Fog shrouds Haleakalā'),
	'fog-shrouds-haleakala');
is(Jaeger::Uri::MakeUriFromTitle(
	'TF-ISL flies over Reykjavík on approach to KEF'),
	'tf-isl-flies-over-reykjavik-on-approach-to-kef');

#is(Jaeger::Uri::MakeUriFromTitle(''), '');

done_testing();
