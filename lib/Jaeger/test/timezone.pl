#!/usr/bin/perl

use strict;

# Test case for Jaeger::Timezone

use Test::More;

# Note: This script is intended to be run from the 'test' directory, since I
# can't figure out a good way to get Perl to include the correct library path 
use lib "../..";

use Jaeger::Timezone;

my $gmt = Jaeger::Timezone->Select(name => "GMT");
my $ist = Jaeger::Timezone->Select(name => "IST");
my $hst = Jaeger::Timezone->Select(name => "HST");
my $cst = Jaeger::Timezone->Select(name => "CST");
my $pst = Jaeger::Timezone->Select(name => "PST");
my $pdt = Jaeger::Timezone->Select(name => "PDT");

is($gmt->format(1575949544), "03:45:44 GMT Tuesday 10 December 2019");
is($ist->format(1575949544), "09:15:44 IST Tuesday 10 December 2019");
is($hst->format(1575949544), "17:45:44 HST Monday 09 December 2019");
is($pst->format(1575949544), "19:45:44 PST Monday 09 December 2019");
is($pdt->format(1575949544), "20:45:44 PDT Monday 09 December 2019");

is($cst->format(912754800), "01:00:00 CST Friday 04 December 1998");
is($cst->format(944281233), "22:20:33 CST Friday 03 December 1999");
is($pdt->format(1571122800), "Tuesday 15 October 2019");

done_testing();
