#!/usr/bin/perl

#
# $Id: user.cgi,v 1.5 2004-11-12 23:35:57 jaeger Exp $
#

# user.cgi: Allows editing and viewing of users

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::User;
use Jaeger::User::Edit;

my $q = Jaeger::Base->Query();
my $lf = Jaeger::Base->Lookfeel();

# users who aren't logged in don't get to see this page
unless(Jaeger::User->Login()) {
	$lf->redirect($Jaeger::Base::BaseURL . 'login.cgi');
}

# show whatever page the user requested

my $page;

if($q->param('action') eq 'edit') {
	# show the "edit thyself" page
	$page = new Jaeger::User::Edit();

} elsif($q->param('user')) {
	# show a specific user
	my $login = $q->param('user');

	$page = Jaeger::User->Select(login => $login);

	unless($page) {
	}

} else {
	# show the list of users
	$page = new Jaeger::User::List;
}

my $html = $lf->main($page);

print "content-type: text/html; charset=UTF-8\n";
foreach my $cookie (@{$page->lf()->{cookies}}) {
	print "Set-Cookie: $cookie\n";
}

print "\n";
print $html;
