#!/usr/bin/perl

# $Id: nautilus-plugin.pl,v 1.1 2007-05-25 18:43:51 jaeger Exp $

# Nautilus plugin for updating rounds of photos.
#
# This script should be installed in ~/.gnome2/nautilus-scripts
#
# We maintain a "todo" directory under the round heigharchy, which contains
# the photos that have not yet been cropped or ignored.
#
# This script may be executed as one of two symlinked binary names:
#
# 	ignore-photo
#		When executed from the todo directory, any arguments are
#		ignored, and the specific round is updated.
#
# 	update-round
# 		When executed from any photo subdirectory, the arguments are
# 		ignored, and the round's todo directory and top-level
# 		todo symlink are updated.
#
# 		When executed from the root photo directory, if no arguments
# 		are given, all rounds are updated.
#
# 		When executed from the root photo directory, and arguments
# 		are given, each argument that corresponds to a photo round
# 		is updated.
#
# Ted Logan
# 25 May 2007

use strict;

use Cwd;

my $pwd = getcwd;

if($0 =~ /ignore-photo/) {
	# Sanity-check that we're in a directory we expect to be

	if($pwd =~ m#photos/dc/[^/]+/todo$#) {
		# Ignore all the photos on the command line
		if(@ARGV) {
			open IGNORE, ">>../.ignore";
			foreach my $file (@ARGV) {
				print IGNORE "$file\n";
				unlink $file;
			}
			close IGNORE;
		}

		# Update the photos in the todo directory
		update_todo('..');
	}
}

if($0 =~ /update-round/) {
	if($pwd =~ m#photos/dc$#) {
		# We are in the top-level directory.
		if(@ARGV) {
			# Update rounds given on the command line
			foreach my $round (@ARGV) {
				update_todo($round);
			}
		} else {
			# Update all rounds
			opendir HERE, '.';
			foreach my $round (grep {-d $_} grep !/^\./, readdir HERE) {
				update_todo($round);
			}
			closedir HERE;
		}

	} elsif($pwd =~ m#photos/dc/([^/]+)#) {
		# We are in a photo directory
		my $round_path = $pwd;
		$round_path =~ s#(photos/dc/[^/]+).*$#$1#;
		update_todo($round_path);
	}
}

# Updates the contents of the todo directory (which must exist) and updates
# the todo-xxx symlinks.
#
# The first argument is the path (relative or absolute) to the round (which
# will have subdirectories "todo", "raw", and "new").
sub update_todo {
	my $round_path = shift;

	warn "Update todo: $round_path\n";

	my $abs_round_path = Cwd::abs_path($round_path);
	unless($abs_round_path =~ m#photos/dc/([^/]+)$#) {
		# This doesn't appear to be a photo directory
		return undef;
	}
	my $round = $1;

	warn "Abs path=$abs_round_path; round=$round\n";

	mkdir "$round_path/new" unless -d "$round_path/new";

	# Read the list of all the files in the raw directory
	opendir RAW, "$round_path/raw";
	my @files = grep /\.jpg$/i, readdir RAW;
	closedir RAW;

	# Read the list of files that should be ignored
	my %ignore;
	if(open IGNORE, "$round_path/.ignore") {
		while(<IGNORE>) {
			chomp;
			$ignore{$_} = 1;
		}
		close IGNORE;
	}

	my $todo_file_count = 0;

	foreach my $file (@files) {
		if(-f "$round_path/new/$file") {
			# File has been cropped; remove it from the todo dir
			unlink "$round_path/todo/$file"
				if -f "$round_path/todo/$file";
		} else {
			# Check whether the file should be ignored
			unless($ignore{$file}) {
				$todo_file_count++;
				if(!-d "$round_path/todo") {
					mkdir "$round_path/todo";
				}
				unless(-f "$round_path/todo/$file") {
					link "$round_path/raw/$file",
						"$round_path/todo/$file";
				}
			}
		}
	}

	if($todo_file_count == 0) {
		rmdir "$round_path/todo";
	}

	my $current_todo_file = glob "$round_path/../$round-*_todo";
	my $new_todo_file = "$round_path/../$round-${todo_file_count}_todo";
	if(defined($current_todo_file)) {
		if($current_todo_file ne $new_todo_file) {
			unlink $current_todo_file;
			if($todo_file_count > 0) {
				symlink "$round/todo", $new_todo_file;
			} else {
				symlink "$round/new", $new_todo_file;
			}
		}
	} else {
		if($todo_file_count > 0) {
			symlink "$round/todo", $new_todo_file;
		} else {
			symlink "$round/new", $new_todo_file;
		}
	}

	return $todo_file_count;
}
