package Jaeger::Comment::Search;

#
# $Id: Search.pm,v 1.1 2004-05-16 16:22:25 jaeger Exp $
#

# package to allow searching of comments

# created  16 May 2004

use strict;

use Jaeger::Search::Searchable;
use Jaeger::Comment;

@Jaeger::Comment::Search::ISA = qw(Jaeger::Search::Searchable);

# returns a list containing the comments for this search
sub _content {
	my $self = shift;

	my $search = $self->{search};

	my @cl = Jaeger::Comment->Select($search->like_status(qw(title body)));

	# rank the comments
	foreach my $comment (@cl) {
		$comment->{rank} = $search->rank(
			$comment->{title}, $comment->{content}
		);
	}

	return @cl;
}

sub what {
	return 'comments';
}

#
# methods used by Jaeger::Search::Searchable to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = 'Comment Search Results';
}
