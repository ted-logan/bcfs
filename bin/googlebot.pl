#!/usr/bin/perl

# Reads access.log and logs when Googlebot has visited

# 01 November 2003

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Base;

my $dbh = $Jaeger::Base::Pgdbh;

#open LOG, '/home/jaeger/weblogs/access.log';

while(<>) {
	my ($ip, $date, $request, $return, $length, $refer, $ua) =
		/^([0-9.]+) - - \[(.*?)\] "(.*?)" (.+) (.+) "(.*?)" "(.*?)"/;
	
	if($ua =~ /googlebot/i) {
		if($request =~ m#changelog/(\d+).html#) {
			print "Googlebot: $1 [$date]\n";

			my $sql = "insert into user_changelog_view (changelog_id, user_id, date) values ($1, 12, '$date')";
			$dbh->do($sql) or die "$sql;\n";
		}
	}
}

#close LOG;
