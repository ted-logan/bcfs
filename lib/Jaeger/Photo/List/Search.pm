package	Jaeger::Photo::List::Search;

# 
# $Id: Search.pm,v 1.1 2003-01-10 06:58:29 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Displays a list of photos and thumbnails according to a round

# created  08 January 2003

use strict;

use Carp;
use Time::Local;

@Jaeger::Photo::List::Search::ISA = qw(Jaeger::Photo::List);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{query} = shift;

	return $self;
}

# returns a list reference containing the photos for this search
sub _photos {
	my $self = shift;

	my %terms;

	my $query = $self->{query};

	# pick out quoted strings
	while($query =~ s/(\+|-)?("|')([a-zA-Z ]+)\2//) {
		$terms{$3} = lc $1;
	}

	# pick out words
	while($query =~ s/(\+|-)?(\w+)//) {
		$terms{$2} = lc $1;
	}

	# FIXME complain if there's anything left in $query

	my %photos;

	# For each term, search and rank each photo
	foreach my $term (keys %terms) {
		my @photos = Jaeger::Photo->Select(
			"lower(description) like '%$term%'"
		);
		foreach my $photo (@photos) {
			$photos{$photo->id()}++;
		}
	}

	# FIXME delete any photos that have a '-' term

	# FIXME delete any photos that don't have a '+' term

	return $self->{photos} = [sort {$a->{date} <=> $b->{date}} map {Jaeger::Photo->new_id($_)} keys %photos];
}

#
# methods used by Jaeger::Lookfeel to show this page
#

sub _title {
	my $self = shift;

	return $self->{title} = "Photo search: $self->{query}";
}
