#!/usr/bin/perl

#
# $Id: loader.pl,v 1.1 2002-05-19 22:56:54 jaeger Exp $
#

# loader.pl: venerable script to do useful stuf

use strict;

use lib '/home/jaeger/programming/webpage/lib';
use Jaeger::Base;

my $dbh = $Jaeger::Base::Pgdbh;

sub load {
	my ($label, $value) = @_;
	$dbh->do("delete from lookfeel where label = '$label'");
	my $sql = "insert into lookfeel (label, value) values ('$label', " .
  		$dbh->quote($value) . ")";
	$dbh->do($sql);
}

undef $/;
foreach my $file (@ARGV) {
	open IF, $file or die "can't open $file: $!";
	my $content = <IF>;
	close IF;
	print "loading $file\n";
	load($file, $content);
}
