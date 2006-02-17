package Fortune;

# $Id: Fortune.pm,v 1.2 2006-02-17 04:11:31 jaeger Exp $
#
# Reads fortune-encapsulated files and spits them out as requested
#
# 11 February 2002
# Ted Logan

use strict;

use Byteorder qw(ntohl);
use Carp;

sub new {
	return bless [], shift;
}

sub read {
	my $self = shift;
	my $filename = shift;
	my $datfile = shift;
	my $buffer;

	unless($datfile) {
		$datfile = $filename . '.dat';
	}

	unless(open F, $filename) {
		carp "Fortune->read(): Can't read fortune file $filename: $!";
		return undef;
	}
	# read the contents of the file
	local $/ = undef;
	my $content = <F>;
	close F;

	unless(open DAT, $datfile) {
		carp "Fortune->read(): Can't read data file $filename: $!";
		return undef;
	}

	# read the header
	seek DAT, 4, 0;
	read DAT, $buffer, 4;
	my $count = ntohl($buffer);
	seek DAT, 20, 0;
	read DAT, $buffer, 1;
	my $delim = $buffer;

	for(my $i = 0; $i < $count; $i++) {
		seek DAT, 24 + $i * 4, 0;
		read DAT, $buffer, 4;
		my $ptr = ntohl($buffer);

		push @$self, substr($content, $ptr, index($content, $delim, $ptr) - $ptr);
	}

	close DAT;

	return $count;
}

sub quote {
	my $self = shift;
	my $pattern = shift;

	my $list = $self;

	if($pattern) {
		$list = [];
		foreach my $quote (@$self) {
			if($quote =~ /$pattern/i) {
				push @$list, $quote;
			}
		}
	}

	if(@$list == 0) {
		return undef;
	}

	return $list->[rand scalar @$list];
}

1;
