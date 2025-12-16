#!/usr/bin/perl

# 

use strict;

use lib "$ENV{BCFS}/lib";

use Jaeger::Server;

my $server = Jaeger::Server->new();
$server->run();
