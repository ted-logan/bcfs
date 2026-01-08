#!/usr/bin/perl

# julian/index.cgi: Shows photos matching the text "Julian"

use strict;

use lib::relative '../lib';

use Jaeger::Calvin;

my $helper = new Jaeger::Calvin('julian');
$helper->{tagline} = 'The continuing adventures of an intrepid grade-schooler';
$helper->html();
