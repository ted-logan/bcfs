#!/usr/bin/perl

#
# $Id: user.cgi,v 1.2 2003-08-25 03:17:38 jaeger Exp $
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
	$lf->redirect('http://jaeger.festing.org/login.cgi');
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

print "content-type: text/html\n";
foreach my $cookie (@{$page->lf()->{cookies}}) {
	warn "Setting cookie $cookie\n";
	print "Set-Cookie: $cookie\n";
}

print "\n";
print $html;
