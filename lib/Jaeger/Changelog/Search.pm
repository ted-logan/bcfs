package Jaeger::Changelog::Search;

#
# $Id: Search.pm,v 1.2 2004-05-16 16:21:09 jaeger Exp $
#

# package to allow searching of changelogs

# created  26 January 2003

use strict;

use Jaeger::Search::Searchable;
use Jaeger::Changelog;

@Jaeger::Changelog::Search::ISA = qw(Jaeger::Search::Searchable);

# returns a list containing the changelogs for this search
sub _content {
	my $self = shift;

	my $search = $self->{search};

	my @cl = Jaeger::Changelog->Select($search->like_status(qw(title content)));

	# rank the changelogs
	foreach my $changelog (@cl) {
		$changelog->{rank} = $search->rank(
			$changelog->{title}, $changelog->{content}
		);
	}

	return @cl;
}

sub what {
	return 'changelogs';
}

#
# methods used by Jaeger::Search::Searchable to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = 'Changelog Search Results';
}
