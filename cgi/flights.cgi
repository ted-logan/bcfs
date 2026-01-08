#!/usr/bin/perl

#
# $Id: flights.cgi,v 1.1 2006-06-22 03:00:44 jaeger Exp $
#

# flights.cgi: Show a table listing all flights I've taken

use strict;

use lib::relative '../lib';

use Jaeger::Flight;
use Jaeger::Lookfeel;

my $lf = Jaeger::Base::Lookfeel();

print "content-type: text/html; charset=UTF-8\n\n";
print $lf->main(new Jaeger::Flight::List);
