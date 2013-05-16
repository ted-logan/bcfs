#!/usr/bin/perl

#
# $Id: loader.pl,v 1.2 2006-02-04 16:44:54 jaeger Exp $
#

# loader.pl: venerable script to do useful stuf

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";
use Jaeger::Base;

my $dbh = Jaeger::Base::Pgdbh();

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
