#!/usr/bin/perl

# calvin/index.cgi: Shows photos matching the text "Calvin"

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Calvin;

my $helper = new Jaeger::Calvin('julian');
$helper->{tagline} = 'The continuing adventures of an intrepid toddler';
$helper->html();
