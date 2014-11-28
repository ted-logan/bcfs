#!/usr/bin/perl

# Perform maintainence on the pending ("todo") photos
#
# Update the "todo" directory based on the photos that haven't yet been
# processed, based on the contents of */todo

use strict;

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

foreach my $file (sort {(stat $a)[9] <=> (stat $b)[9]} <*/todo/*>) {
	my ($round, $number) = $file =~ m(^(\w+)/todo/(\w+)\.jpg);
	my $todo = "todo/${round}_${number}.jpg";
	delete $todo{$todo};
	unless(-f $todo) {
		link $file, $todo;
	}
	printf "%s    %s/%s\n",
		scalar(localtime ((stat $file)[9])),
		$round, $number;
}

unlink keys %todo;
