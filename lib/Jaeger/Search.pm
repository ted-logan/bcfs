package	Jaeger::Search;

# 
# $Id: Search.pm,v 1.3 2007-05-04 01:54:20 jaeger Exp $
#
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Generalized search code; used by each specific search method

# created  08 January 2003

use strict;

use Carp;
use Time::Local;

@Jaeger::Search::ISA = qw(Jaeger::Base);

use Jaeger::Photo::Search;
use Jaeger::Changelog::Search;
use Jaeger::Comment::Search;

use Carp;

# the number of search items to show per page
$Jaeger::Search::Page = 10;

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{query} = shift;

	return $self;
}

#
# Methods used by table-specific search objects
#

# used internally; returns a hash reference containing the search terms
# and any modifiers
sub _terms {
	my $self = shift;

	my %terms;

	my $query = $self->{query};

	# pick out quoted strings
	while($query =~ s/(\+|-)?("|')([a-zA-Z ]+)\2//) {
		$terms{lc $3} = $1;
	}

	# pick out words
	while($query =~ s/(\+|-)?(\w+)//) {
		$terms{lc $2} = $1;
	}

	# FIXME complain if there's anything left in $query

	return $self->{terms} = \%terms;
}

# returns the SQL where clause to be inserted into the appropiate select
# statement according to the given list of columns
sub like {
	my $self = shift;

	my $terms = $self->terms();

	my @where;

	foreach my $term (keys %$terms) {
		next if $terms->{$term} eq '-';
		$term =~ s/ /%/g;
#		$term =~ s/\s+/[ \\\\t\\\\n]+/g;

		my @colwhere;

		foreach my $column (@_) {
			push @colwhere, "$column ilike '\%$term\%'";
#			push @colwhere, "$column ~* '$term'";
		}

		push @where, '(' . join(' or ', @colwhere) . ')';
	}

	my $where = join(' and ', @where);
	return $where;
}

# Return a similar SQL where clause to like() above, except with
# "status <= $status" at the beginning, for content that might be restricted
sub like_status {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return "status <= $status and (" . $self->like(@_) . ')';
}

# returns an integer rank for the input column(s)
sub rank {
	my $self = shift;

	my $terms = $self->terms();

	my $rank = 0;

	# count the number of times the search criterion show up in the
	# input column(s)
	foreach my $column (@_) {
		foreach my $term (keys %$terms) {
			my $count = 0;
			while($column =~ /$term/ig) {
				$count++;
			}

			# Reject this column unless it contains a '+' term
			if($terms->{$term} eq '+' && !$count) {
				return 0;
			}

			# Reject this column if it contains a '-' term
			if($terms->{$term} eq '-' && $count) {
				return 0;
			}

			$rank += $count;
		}
	}

	return $rank;
}

#
# methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	if($self->{query}) {
		return $self->{title} = "Search: $self->{query}";
	} else {
		return $self->{title} = "Search";
	}
}

sub _html {
	my $self = shift;

	# did we end up with a search query?
	unless($self->{query}) {
		return $self->lf()->search();
	}

	my @what = Jaeger::Base::Query()->param('search');
	unless(@what) {
		@what = qw(all);
	}

	my @results;

	# photo results
	if(grep /(all|photo)/, @what) {
		my $search = new Jaeger::Photo::Search($self);
		push @results, {
			count => $search->count(),
			html => $search->html()
		};
	}

	# changelog results
	if(grep /(all|changelog)/, @what) {
		my $search = new Jaeger::Changelog::Search($self);
		push @results, {
			count => $search->count(),
			html => $search->html()
		};
	}

	# comment results
	if(grep /(all|comment)/, @what) {
		my $search = new Jaeger::Comment::Search($self);
		push @results, {
			count => $search->count(),
			html => $search->html()
		};
	}

	# sort searches according to the number of hits
	return join '', map {$_->{html}}
		sort {$b->{count} <=> $a->{count}} @results;
}
