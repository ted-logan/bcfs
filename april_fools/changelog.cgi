#!/usr/bin/perl

print "content-type: text/html\n\n";

my $param = $ENV{QUERY_STRING} ? '?' . $ENV{QUERY_STRING} : '';

open AF, "/home/jaeger/public_html/april_fools.html";
while(<AF>) {
	s/\${PARAM}/$param/;
	print;
}
close AF;
