package Jaeger::Journal::Search;

#
# $Id: Search.pm,v 1.1 2003-01-26 12:49:11 jaeger Exp $
#

# package to allow searching of journals

# 26 January 2003
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Search::Searchable;
use Jaeger::Journal;

@Jaeger::Journal::Search::ISA = qw(Jaeger::Search::Searchable);

# returns a list containing the journals for this search
# Jaeger::Search::Searchable caresses the data returned
sub _content {
	my $self = shift;

	my $search = $self->{search};

	my @journals = Jaeger::Journal->Select($search->like('content'));

	# rank the journals
	foreach my $journal (@journals) {
		$journal->{rank} = $search->rank($journal->{content});
	}

	return @journals;
}

sub what {
	return 'journals';
}

#
# methods used by Jaeger::Search::Searchable to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = 'Journal Search Results';
}
