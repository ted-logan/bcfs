#!/usr/bin/perl

# 

use strict;

use lib "$ENV{BCFS}/lib";

use Jaeger::Server;

#use Log::Any::Adapter('Screen', log_level => 'debug');
#use Log::Any::Adapter('Stderr');

use Log::Any::Adapter;
Log::Any::Adapter->set('Screen',
     min_level => 'debug', # default is 'warning'
);

my $server = Jaeger::Server->new();
$server->run();
