package	Library::Author;

# 
# $Id: Author.pm,v 1.1 2003-12-01 02:37:42 jaeger Exp $
#
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Wraps the 'author' table

# created  27 November 2003

use strict;

use Jaeger::Base;

@Library::Author::ISA = qw(Jaeger::Base);

use Carp;

use Library::Book;

sub table {
	return 'author';
}

# Sanity-checks parameters
sub update {
	my $self = shift;

	unless($self->{name_last}) {
		croak "$self name_last must be set";
	}

	unless($self->{name_first}) {
		croak "$self name_first must be set";
	}

	$self->SUPER::update();
}

# Returns an array reference containing the books this author has written
sub _books {
	my $self = shift;

	return Jaeger::Mapper->Map(
		table => 'book_author_map',
		idfield => 'author_id',
		id => $self->id(),
		field => 'book_id',
		'package' => 'Library::Book',
	);
}
