#!/usr/bin/perl

#
# $Id: login.cgi,v 1.1 2003-08-24 16:21:56 jaeger Exp $
#

# login.cgi: Logs a user in

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::User;

my $q = Jaeger::Base->Query();
my $lf = Jaeger::Base->Lookfeel();

# The message given to the user if login fails
my $message;

# do we already have a cookie?
my $user = Jaeger::User->Login();

# Has a user attempted to log in?
my $login = $q->param('login');
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
			$redirect = 'http://jaeger.festing.org/changelog/';
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
	redirect => $q->param('redirect'),
);

print "content-type: text/html\n\n";
print $lf->main($page);
