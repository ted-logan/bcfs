#!/usr/bin/perl

#
# $Id: user.cgi,v 1.1 2003-08-24 20:54:08 jaeger Exp $
#

# user.cgi: Allows editing and viewing of users

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::User;
use Jaeger::User::Edit;

my $q = Jaeger::Base->Query();
my $lf = Jaeger::Base->Lookfeel();

my $page;

if($q->param('action') eq 'edit') {
	$page = new Jaeger::User::Edit();
} else {
	$page = new Jaeger::Base;
	$page->{title} = 'Users';
}

my $html = $lf->main($page);

print "content-type: text/html\n";
foreach my $cookie (@{$page->lf()->{cookies}}) {
	warn "Setting cookie $cookie\n";
	print "Set-Cookie: $cookie\n";
}

print "\n";
print $html;
