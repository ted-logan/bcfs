package Jaeger::Search::Searchable;

#
# $Id: Searchable.pm,v 1.1 2003-01-26 12:50:52 jaeger Exp $
#

# Module containing utility functions for searchable objects
# All Jaeger::*::Search modules derive from this module
#
# The derived module is responsible for implementing _content and _html

# created  26 January 2002

use strict;

use Jaeger::Search;

@Jaeger::Search::Searchable::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	my $param = shift;

	if(ref($param) eq 'Jaeger::Search') {
		$self->{search} = $param;
	} else {
		$self->{search} = new Jaeger::Search($param);
	}

	$self->{page} = $self->query()->param('page');

	return $self;
}

# Returns a list reference containing the data for this search
sub content {
	my $self = shift;

	unless($self->{content}) {
		# get the unsorted list of ranked content, and sort it
		my @sorted = sort {$b->{rank} <=> $a->{rank}} grep {$_->{rank}}
			$self->_content();

		# record the total number of results
		$self->{count} = @sorted;

		# Pick the appropiate page of output
		my $min = $self->{page} * $Jaeger::Search::Page;
		my $max = ($self->{page} + 1) * $Jaeger::Search::Page - 1;
		$self->{content} = [@sorted[$min .. $max]];
	}

	return $self->{content};
}

# returns the total number of results
sub _count {
	my $self = shift;

	$self->content();

	return $self->{count};
}

# shows the html for this search result
sub html {
	my $self = shift;

	return $self->lf()->search_results(
		title => $self->title(),
		count => $self->count(),
		content => $self->_html(),
		page => $self->{page},
		what => $self->what(),
		q => $self->query()->param('q'),
	);
}

# This function is run for derived classes that need only text formatting
# for their search results.
#
# In the future, this function will also pick out sentences containing the
# search queries and prominently display them.
sub _html {
	my $self = shift;

	my @content;

	foreach my $cl (@{$self->content()}) {
		next unless $cl;
		push @content, $self->lf()->search_results_text(
			url => $cl->url(),
			title => $cl->title(),
			time_begin => $cl->time_begin(),
		);
	}

	return join('', @content);
}
