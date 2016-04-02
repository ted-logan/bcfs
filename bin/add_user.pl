#!/usr/bin/perl

# Admin interface for adding a user, since I don't trust users to add
# themselves (since it's been about a decade since a real person wanted an
# account).

use strict;

use lib "$ENV{BCFS}/lib";
use Jaeger::User;
use Jaeger::User::Create;

my ($login, $name, $email, $status) = @ARGV;

unless(defined($login) && defined($name) && defined($email)) {
	die "Usage: $0 LOGIN NAME EMAIL [STATUS]\n";
}

my $user = Jaeger::User::Create->step1_adduser(
	login => $login,
	name => $name,
	email => $email,
	status => $status,
);

print "User created:\n";
print "Login: $user->{login}\n";
print "Name: $user->{name}\n";
print "Email: $user->{email}\n";
print "Status: $user->{status}\n";
print "Password: $user->{plain_password}\n";
