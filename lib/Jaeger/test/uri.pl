#!/usr/bin/perl

use strict;

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
done_testing();
