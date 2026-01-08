#!/usr/bin/perl

#
# $Id: logout.cgi,v 1.2 2004-11-12 23:35:57 jaeger Exp $
#

# logout.cgi: removes a user's cookies, logging him out

use strict;

use lib::relative '../lib';

use Jaeger::User;
use Jaeger::Lookfeel;

my $q = Jaeger::Base->Query();
my $lf = Jaeger::Base->Lookfeel();

# clear the user's cookies, if they should happen to exist
print "content-type: text/html; charset=UTF-8\n";
print "Set-cookie: ", $q->cookie(
	-name => 'session',
	-value => '',
	-expires => '-1h'
), "\n";
print "Set-cookie: ", $q->cookie(
	-name => 'jaeger_login',
	-value => '',
	-expires => '-1h'
), "\n";
print "Set-cookie: ", $q->cookie(
	-name => 'jaeger_password',
	-value => '',
	-expires => '-1h'
), "\n";
print "\n";

$Jaeger::User::Current = undef;

my $page;

# Show the logout sucessful message
$page = new Jaeger::Base;
$page->{title} = 'Logged out';
$page->{html} = $lf->logout();

print $lf->main($page);
