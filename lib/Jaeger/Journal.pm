package		Jaeger::Journal;

#
# $Id: Journal.pm,v 1.5 2003-01-26 12:45:05 jaeger Exp $
#

# Journal-controlling code

# 25 August 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

use Time::Local;

@Jaeger::Journal::ISA = qw(Jaeger::Base);

$Jaeger::Journal::Dir = '/home/jaeger/journal';

sub table {
	return 'journal';
}

# the title of this journal entry
# (There is inevitibally a better way to do this.)
sub _title {
	my $self = shift;

	my @date = split /-/, $self->{entrydate};
	my @date_local = @date;
	$date_local[0] -= 1900;
	$date_local[1]--;
	my $time = timelocal(0, 0, 0, reverse @date_local);
	my $weekday = $Jaeger::Base::Weekdays[(localtime $time)[6]];

	return $self->{title} =
		"$weekday $date[2] $Jaeger::Base::Months[$date[1]] $date[0]";
}

# the url for this entry
sub _url {
	my $self = shift;

	my $date = $self->{entrydate};
	$date =~ s/-/\./g;

	return $self->{url} = "/cgi-bin/journal.pl?$date";
}

# reads the journal entry from the designated file
sub read {
	my $self = shift;

	my $file = shift;

	open J, $file or die "Can't open $file: $!\n";
	my @content = <J>;
	close J;

	# get the last modification date
	$self->{time_begin} = scalar localtime((stat $file)[9]);

	# do we have a comment telling us when the file was started?
	if(my ($start) = $content[0] =~ /started (.*) --/) {
		$self->{time_end} = $start;
	} else {
		$self->{time_end} = $self->{time_begin};
	}

	# consume lines until we get to the open <body> tag
	while(1) {
		my $line = shift @content;
		last if $line =~ /body/i;
	}

	# the last line probably contains just </body>
	if($content[-1] =~ /\/body/i) {
		pop @content;
	}

	$self->{content} = join('', @content);
}

# load any remaining journals from the filesystem into the database
sub Load {
	opendir JOURNALDIR, $Jaeger::Journal::Dir
		or return undef;
	my @entries = sort grep /^\d\d\d\d\.\d\d\.\d\d\.html$/,
		readdir JOURNALDIR;
	closedir JOURNALDIR;

	foreach my $entry (@entries) {
		my $date = $entry;
		$date =~ s/\.html//;
		$date =~ s/\./-/g;

		unless(Jaeger::Journal->Select(entrydate => $date)) {
			my $journal = new Jaeger::Journal;
			$journal->{entrydate} = $date;
			$journal->read("$Jaeger::Journal::Dir/$entry");

			print "Read journal $date\n";
			if($journal->{time_begin} eq $journal->{time_end}) {
				print "Finished: $journal->{time_end}\n";
			} else {
				print "Started:  $journal->{time_begin}\n";
				print "Finished: $journal->{time_end}\n";
			}
			print "Size:     ", length($journal->{content}), " bytes\n";
			print "\n";

			$journal->update();
		}
	}
}

# produce html for the latest ten journal entries
# Now, it selects the entries from the database
sub Navbar {
	my $lf = new Jaeger::Lookfeel;

	my @links;

	my @entries = Jaeger::Journal->Select(
		'1=1 order by entrydate desc limit 10'
	);

	foreach my $entry (@entries) {
		push @links, $lf->link(
			url => $entry->url(),
			title => $entry->title(),
		);
	}

	return $lf->linkbox(
		url => '/cgi-bin/journal.pl',
		title => 'Journals',
		links => join('', @links)
	);
}

1;
