#!/usr/bin/perl

#
# $Id: login.cgi,v 1.4 2004-11-12 23:35:57 jaeger Exp $
#

# login.cgi: Logs a user in

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::User;
use Jaeger::Lookfeel;

my $q = Jaeger::Base->Query();
my $lf = Jaeger::Base->Lookfeel();

# The message given to the user if login fails
my $message;

# do we already have a cookie?
my $user = Jaeger::User->Login();

# Has a user attempted to log in?
my $login = lc $q->param('login');
my $password = $q->param('password');
if(($login && $password) || $user) {
	unless($user) {
		$user = Jaeger::User->Login($login, $password);
	}

	if($user) {
		# Save the relevant cookie
		$user->cookies();

		# Redirect somewhere
		my $redirect = $q->param('redirect');
		unless($redirect) {
			$redirect = 'changelog/';
		}

		# confirm the account if status == 0
		if($user->{status} == 0) {
			$redirect = 'create.cgi?step=2';
		}

		$user->redirect($redirect);
	} else {
		# login failed
		$message = '<p>Login failed. Sorry.</p>';
	}
}

my $page;

# Show the login dialog
$page = new Jaeger::Base;
$page->{title} = 'Log In';
$page->{html} = $lf->login(
	message => $message,
	redirect => scalar $q->param('redirect'),
);

print "content-type: text/html; charset=UTF-8\n\n";
print $lf->main($page);
