#!/usr/bin/perl

#
# $Id: content.pl,v 1.2 2004-02-16 02:59:13 jaeger Exp $
#

# content.pl: Allows editing of static content
#
# 16 January 2003
# Ted Logan (jaeger@festing.org)

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Content;

# figure out what content we're using
my $title = shift;

unless($title) {
	die "Usage: $0 TITLE [PARENT]\n"; 
}

my $content = Jaeger::Content->Select(label => $title);

unless($content) {
	my $parent = shift;

	$content = new Jaeger::Content;
	$content->{label} = $title;
	$content->{parent} = $parent;
}

print "Title: $title", ($content->{timestamp} ? '' : ' (new)'), "\n";
if($content->{parent}) {
	print "Parent: $content->{parent}\n";
} else {
	print "Parent: (null)\n";
}

{
	my @sibblings = map {$_->{label}} $content->sibblings();
	print "Sibblings: ", (@sibblings ? "@sibblings" : '(none)'), "\n";
}

{
	my @children = map {$_->{label}} $content->children();
	print "Children: ", (@children ? "@children" : '(none)'), "\n";
}

{
	my @commands = (
		e => 'Edit',
		i => 'Use ispell(1)',
		y => 'Insert',
		q => 'Abandon changes',
	);

	my %commands = @commands;

	sub menu {
		my $choice;

		do {
			# show the menu
			print "\n";
			for(my $i = 0; $i < @commands; $i += 2) {
				print "($commands[$i]) $commands[$i + 1]\n";
			}

			# get input
			print "Master? ";
			$choice = lc <STDIN>;
			chomp $choice;

		} until(exists $commands{$choice});

		return $choice;
	}
}

my $dirty = 0;

while(1) {
	my $choice = menu();

	if($choice eq 'e') {
		$dirty ||= $content->pipe(qq(vi "+set textwidth=72"));

	} elsif($choice eq 'i') {
		$dirty ||= $content->pipe('aspell');

	} elsif($choice eq 'y') {
		if($dirty) {
			$content->{timestamp} = scalar localtime time;
			$content->update();
		}
		exit;

	} elsif($choice eq 'q') {
		# abandon any changes
		exit;
	}
}
