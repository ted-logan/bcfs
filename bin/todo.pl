#!/usr/bin/perl

# Perform maintainence on the pending ("todo") photos
#
# Update the "todo" directory based on the photos that haven't yet been
# processed, based on the contents of */todo

use strict;

use POSIX qw(strftime);

#
# First, update each round's "todo" directory
#
system("~/.gnome2/nautilus-scripts/update-round") == 0
	or warn "Unable to update pending rounds: $!\n";

#
# Next, update the global todo directory with every pending file
#

# The contents of the current "todo" directory
my %todo = map {$_, undef} <todo/*>;

my %months;

foreach my $file (sort {(stat $a)[9] <=> (stat $b)[9]} <*/todo/*>) {
	my ($round, $number) = $file =~ m(^(\w+)/todo/(\w+)\.jpg);
	my $todo = "todo/${round}_${number}.jpg";
	delete $todo{$todo};
	unless(-f $todo) {
		link $file, $todo;
	}
	my $m = strftime("%Y-%m", localtime ((stat $file)[9]));
	$months{$m}->{count}++;
	$months{$m}->{round}->{$round}++;
}

unlink keys %todo;

print "\n";
foreach my $month (sort keys %months) {
	printf "%s: %3d photo%s  (round%s ",
		$month, $months{$month}->{count},
		$months{$month}->{count} > 1 ? "s" : " ",,
		%{$months{$month}->{round}} > 1 ? "s" : " ";
	print join(' ', sort keys %{$months{$month}->{round}});
	print ")\n";
}
