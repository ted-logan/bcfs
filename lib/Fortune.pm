package Fortune;

# $Id: Fortune.pm,v 1.1 2002-05-19 22:54:05 jaeger Exp $
#
# Reads fortune-encapsulated files and spits them out as requested
#
# 11 February 2002
# Ted Logan

use strict;

use Byteorder qw(ntohl);

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

	open F, $filename;
	# read the contents of the file
	local $/ = undef;
	my $content = <F>;
	close F;

	open DAT, $datfile;

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
