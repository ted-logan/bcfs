#!/usr/bin/perl

#
# $Id: search.cgi,v 1.2 2004-11-12 23:35:57 jaeger Exp $
#

# Performs a search

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Search;
use Jaeger::Lookfeel;

my $q = Jaeger::Base::Query();
my $lf = Jaeger::Base::Lookfeel();

my $search = new Jaeger::Search($q->param('q'));

print "content-type: text/html; charset=UTF-8\n\n";
print $lf->main($search);
