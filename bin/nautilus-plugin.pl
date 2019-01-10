#!/usr/bin/perl

# $Id: nautilus-plugin.pl,v 1.1 2007-05-25 18:43:51 jaeger Exp $

# Nautilus plugin for updating rounds of photos.
#
# This script should be installed in ~/.local/share/nautilus/scripts/
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
use Image::Magick;

my $pwd = getcwd;

if($0 =~ /ignore-photo/) {
	# Sanity-check that we're in a directory we expect to be

	if($pwd =~ m#photos/dc/([^/]+)/todo$#) {
		# Ignore all the photos on the command line
		if(@ARGV) {
			open IGNORE, ">>../.ignore";
			foreach my $file (@ARGV) {
				print IGNORE "$file\n";
				unlink $file;
				unlink "../../todo/$1_$file";
			}
			close IGNORE;
		}

		# Update the photos in the todo directory
		update_todo('..');
	} elsif($pwd =~ m#photos/dc/todo$#) {
		# This is the master todo directory. Photos are listed here as
		# "round_number.jpg". Figure out the round and number for each
		# photo on the command line.
		foreach my $file (@ARGV) {
			if(my ($round, $number) =
					$file =~ /^([^_]+)_([^_]+)\.jpg$/) {
				open IGNORE, ">>../$round/.ignore";
				print IGNORE "$number.jpg\n";
				close IGNORE;
				unlink $file;
				unlink "../$round/todo/$number.jpg";
			}
		}
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
			foreach my $round (sort grep {-d $_ && ! -l $_} grep !/^\./, readdir HERE) {
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

# Updates the contents of the todo directory (which must exist)
#
# The first argument is the path (relative or absolute) to the round (which
# will have subdirectories "todo", "raw", and "new").
sub update_todo {
	my $round_path = shift;

	my $abs_round_path = Cwd::abs_path($round_path);
	unless($abs_round_path =~ m#photos/dc/([^/]+)$#) {
		# This doesn't appear to be a photo directory
		return undef;
	}
	my $round = $1;

	if($round eq 'todo') {
		# This is not a real round, but a directory containing all
		# pending pictures
		return undef;
	}

	mkdir "$round_path/full" unless -d "$round_path/full";
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
		if(-f "$round_path/full/$file" && !-f "$round_path/new/$file") {
			# Full-sized image that will be cropped down for posting
			my ($width, $height) = qw(1600 1200);

			my $img = new Image::Magick;
			$img->Read("$round_path/full/$file");
			my ($owidth, $oheight) = $img->Get('width', 'height');

			my ($nwidth, $nheight);

			my $aspect = $owidth / $oheight;
			if($aspect > ($width / $height)) {
				$nwidth = $width;
				$nheight = int($width / $aspect);
			} else {
				$nwidth = int($height * $aspect);
				$nheight = $height;
			}

			if(($nwidth > $owidth) || ($nheight > $oheight)) {
				# Image is full-size anyway
				link "$round_path/full/$file",
					"$round_path/new/$file";
			} else {
				$img->Resize(width => $nwidth,
					height => $nheight);
				$img->Set(quality => 85);
				$img->Write("$round_path/new/$file");
			}
		}

		if(-f "$round_path/new/$file") {
			# File has been cropped; remove it from the todo dir
			unlink "$round_path/todo/$file"
				if -f "$round_path/todo/$file";
			unlink "$round_path/../todo/${round}_${file}";
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

	printf "%s: %3d todo\n",
		$round, $todo_file_count;

	if($todo_file_count == 0) {
		if(-d "$round_path/todo") {
			rmdir "$round_path/todo"
				or warn "Can't remove $round_path/todo: $!\n";
		}
		if(-d "$round_path/raw") {
			unlink glob "$round_path/raw/*";
			rmdir "$round_path/raw"
				or warn "Can't remove $round_path/raw: $!\n";
		}
	}

	my $current_todo_file = glob "$round_path/../$round-*_todo";
	if(defined($current_todo_file)) {
		unlink $current_todo_file;
	}

	return $todo_file_count;
}
