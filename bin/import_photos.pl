#!/usr/bin/perl

package Photos;

#
# Photos module: manipulates a round of photos
#

use strict;

use Data::Dumper;

sub new {
	return bless {}, shift;
}

sub read_list {
	my $photos = shift;

	my $file = shift;

	open LIST, $file
		or die "Can't open list $file $!\n";

	while(<LIST>) {
		if(my ($number, $date) = /(\d+)\s+\d+.+- (.*)/) {
			# I'm not sure what 'N/A' means for the date, but
			# we can let the previous mechanism for date-finding
			# to take care of it
			next if $date eq 'N/A';

			$number = sprintf '%02d', $number;
			if(my ($timezone) = $date =~ /([A-Z]{3})/) {
				$photos->{$number}->{timezone} = $timezone;
			} else {
				$date .= ' GMT';
			}
			$photos->{$number}->{date} = `date --date="$date" +%s`;
			chomp $photos->{$number}->{date};
			unless($photos->{$number}->{date}) {
				die "$file: Invalid date: $date\n";
			}
		}
	}

	close LIST;
}

sub read_notes {
	my $photos = shift;

	my $file = shift;

	my $date = undef;

	open NOTES, $file
		or die "Can't open notes $file: $!\n";
	while(<NOTES>) {
		if(my ($photo, $desc) = /(.*?)\s+(.*)/) {
			if($photo eq 'date') {
				$date = `date --date="$desc" +%s`;
				chomp $date;

				# fix the date according to the (guessed)
				# time zone

			} elsif($photo =~ s/\.jpg//) {
				$photos->{$photo}->{description} = $desc;
				$photos->{$photo}->{date} = $date;
				$photos->{$photo}->{hidden} = 0;

			} else {
				die "invalid line: $_";
			}
		}
	}
	close NOTES;
}

sub read_directory {
	my $photos = shift;

	my $dir = shift;

	opendir DIR, $dir
		or die "Can't open photo dir $dir: $!\n";
	foreach my $file (grep /\.jpg$/, readdir DIR) {
		my $photo = $file;
		if($dir =~ /(129|133)/) {
			$photo =~ s/0000_//;
		} else {
			$photo =~ s/0000_0//;
		}
		$photo =~ s/\.jpg//;
		$photos->{$photo}->{date} = (stat "$dir/$file")[9];
	}
	closedir DIR;
}

sub show {
	my $photos = shift;

	my $round = shift;

	foreach my $photo (sort keys %$photos) {
		my $p = Jaeger::Photo->new();
		$p->{round} = $round;
		$p->{number} = $photo;
		$p->{location} = Jaeger::Location->new_id(1);
		$p->{description} = $photos->{$photo}->{description};
		$p->{hidden} = $photos->{$photo}->{hidden};

		my $hidden = $photos->{$photo}->{hidden} ? '*' : ' ';

		if($photos->{$photo}->{date}) {
			my $tz = $photos->{$photo}->{timezone} ?
				$photos->{$photo}->{timezone} :
				$photos->timezone($photos->{$photo}->{date});
			my $timezone = Jaeger::Timezone->Select(name => $tz);
			unless($timezone) {
				die "Can't get timezone for $round/$photo $tz! (", scalar(localtime $photos->{$photo}->{date}), "\n";
			}

			$p->{date} = $photos->{$photo}->{date};
			$p->{timezone} = $timezone;

			print "$round/$photo  $hidden  ", $timezone->format($photos->{$photo}->{date}),
				"  ", $photos->{$photo}->{description}, "\n";
		} else {
			# this photo has no date
			$p->{date} = 0;
			$p->{timezone} = Jaeger::Timezone->Select(name=> 'GMT');

			print "$round/$photo  $hidden  $photos->{$photo}->{description}\n";
		}

		$p->update() or die "Photo insert failed!\n";
	}
}

sub set_hidden {
	my $photos = shift;

	my $hidden = shift;

	foreach my $photo (sort keys %$photos) {
		unless(defined $photos->{$photo}->{hidden}) {
			$photos->{$photo}->{hidden} = $hidden;
		}
	}
}
	

%Photos::Timezones = (
	'01 December 1998' => 'CST',
	'17 December 1998' => 'MST',
	'03 January 1999' => 'CST',
	'10 February 1999' => 'MST',
	'14 February 1999' => 'CST',
	'05 March 1999' => 'MST',
	'08 March 1999' => 'CST',
	'04 April 1999' => 'CDT',
	'16 April 2000' => 'MDT',
	'18 April 2000' => 'CDT',
	'29 May 2000' => 'MDT',
	'28 June 2000' => 'EDT',
	'15:00 16 July 2000' => 'CDT',
	'23 July 2000' => 'MDT',
	'11 September 2000' => 'CDT',
	'26 September 2000' => 'PDT',
	'31 October 2000' => 'PST',
	'23 December 2000' => 'MST',
	'31 January 2001' => 'PST',
	'15 March 2001' => 'MST',
	'25 March 2001' => 'PST',
	'01 April 2001' => 'PDT',
	'26 May 2001' => 'MDT',
	'03 June 2001' => 'PDT',
	'07 June 2001' => 'MDT',
	'31 August 2001' => 'PDT',
	'05 September 2001' => 'MDT',
	'07 September 2001' => 'CDT',
	'11 September 2001' => 'MDT',
	'25 October 2001' => 'PDT',
	'04 November 2001' => 'PST',
	'20 November 2001' => 'MST',
	'21:00 MST 25 November 2001' => 'PST',
	'16 December 2001' => 'MST',
	'21 December 2001' => 'PST',
	'14 April 2002' => 'PDT',
	'30 June 2002' => 'MDT',
	'22 July 2002' => 'PDT',
	'15 August 2002' => 'MDT',
	'27 October 2002' => 'MST',
	'24 November 2002' => 'PST',
	'30 November 2002' => 'MST',
	'25 December 2002' => 'CET',
	'04 January 2003' => 'MST'
);

# process the timezone information appropiatly
{
	my %tzcache = %Photos::Timezones;
	%Photos::Timezones = ();

	foreach my $date (keys %tzcache) {
		my $time = `date --date="$date" +%s`;
		unless($time) {
			die "Timezone info: Invalid date: $date\n";
		}

		chomp $time;
		$Photos::Timezones{$time} = $tzcache{$date};
	}
}

sub timezone {
	my $photos = shift;

	my $date = shift;

	my $tz;
	my $select_tz;

	foreach my $this_tz (keys %Photos::Timezones) {
		if(($this_tz <= $date) && ($this_tz > $select_tz)) {
			$select_tz = $this_tz;
			$tz = $Photos::Timezones{$this_tz};
		}
	}

	return $tz;
}

package main;

#
# main package
#

use strict;

use lib '/home/jaeger/programming/webpage/lib';

use Jaeger::Photo;

use Data::Dumper;

my $photodir = '/home/jaeger/graphics/photos/dc';

my @rounds;

if(@ARGV) {
	# specify rounds on the command line
	@rounds = @ARGV;

} else {
	# use all available rounds
	opendir PHOTOS, $photodir
		or die "Can't open $photodir: $!\n";
	@rounds = sort grep !/^\./, readdir PHOTOS;
	closedir PHOTOS;
}

my $count = 0;

foreach my $dir (@rounds) {
	next unless -d "$photodir/$dir";
#	print $dir, "\n";

	my $photos = new Photos;

	# default policy: is a photo from this round hidden or not?
	my $hidden;

	if($dir < 54) {
		# read the photo directory, which had better exist
#		print "\tReading directory\n";
		$photos->read_directory("$photodir/$dir");
	}

	# read notes.txt, if it exists
	if(-f "$photodir/$dir/new/notes.txt") {
#		print "\tReading notes.txt\n";
		$photos->read_notes("$photodir/$dir/new/notes.txt");

		# by default, photos will be hidden
		$hidden = 1;
	} else {
		# this round has not been cropped; photos will not be hidden
		$hidden = 0;
	}

	if($dir >= 54) {
		# read the photo directory, which had better exist
#		print "\tReading directory\n";
		$photos->read_directory("$photodir/$dir");
	}

	# read list.txt, if it exists
	if(-f "$photodir/$dir/list.txt") {
#		print "\treading list.txt\n";
		$photos->read_list("$photodir/$dir/list.txt");
	}

	$photos->set_hidden($hidden);

	$photos->show($dir);

#	last if $count++ > 10;
}
