#!/usr/bin/perl

#
# $Id: create.cgi,v 1.2 2004-11-12 23:35:57 jaeger Exp $
#

# create.cgi: Allows a user to be created

use strict;

use lib::relative '../lib';

use Jaeger::User::Create;
use Jaeger::Lookfeel;

my $lf = Jaeger::Base->Lookfeel();

my $page = new Jaeger::User::Create;

print "content-type: text/html; charset=UTF-8\n\n";
print $lf->main($page);
