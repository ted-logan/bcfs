#!/usr/bin/perl

#
# $Id: create.cgi,v 1.1 2003-08-25 03:20:09 jaeger Exp $
#

# create.cgi: Allows a user to be created

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::User::Create;

my $lf = Jaeger::Base->Lookfeel();

my $page = new Jaeger::User::Create;

print "content-type: text/html\n\n";
print $lf->main($page);
