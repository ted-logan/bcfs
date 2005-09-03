#!/usr/bin/perl

# $Id:
#
# This script will create an .htpasswd file for users specified by the
# "whereclause" argument.
#
# htpasswd.pl FILE [WHERECLAUSE]
#
# Example:
#  htpasswd.pl .htpasswd "status >= 20"
# 	Creates a file named .htpasswd in the current directory containing
# 	users whose status is "elite" or better.
#
# 3 September 2005
# Ted Logan

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::User;

my ($file, $whereclause) = @ARGV;

unless($file) {
	die "Usage: $0 FILE [WHERECLAUSE]\n";
}

open FILE, ">$file"
	or die "Can't write $file: $!\n";

foreach my $user (Jaeger::User->Select($whereclause)) {
	print FILE "$user->{login}:$user->{password}\n";
}

close FILE;
