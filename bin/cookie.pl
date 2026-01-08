#!/usr/bin/perl

use strict;

use lib::relative '../lib';

use Getopt::Long;

use Jaeger::Changelog;
use Jaeger::User;

my $login;
my $url;

GetOptions(
	"login=s" => \$login,
	"changelog=s" => \$url)
or die "Error in command line arguments\n";

unless($login) {
	die "--login=USER not specified\n";
}

unless($url) {
	die "--changelog=URL not specified\n";
}

my $user = Jaeger::User->Select(login => $login);
unless($user) {
	die "User \"$login\" not found\n";
}


my $uri = $url;
$uri =~ s(^https?://.*?/)(/);
my $changelog = Jaeger::Changelog::Urimap($uri, $user);
unless($changelog) {
	die "Changelog \"$changelog\" not found\n";
}

print "Changelog is $changelog\n";

print "Magic url for ", $user->login(), ":\n";
print $changelog->url() . "?cookie=" . $user->cookie() . "\n";
