package	Library::Book;

# 
# $Id: Book.pm,v 1.1 2003-12-01 02:37:42 jaeger Exp $
#
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Wraps the 'book' table

# created  27 November 2003

use strict;

use Jaeger::Base;

@Library::Book::ISA = qw(Jaeger::Base);

use Carp;

use Library::Author;
use Library::Subject;
use Library::Series;

sub table {
	return 'book';
}

sub update {
	my $self = shift;

	unless($self->{title}) {
		croak "$self title must be defined";
	}

	$self->{isbn} =~ s/[- ]//g;

	$self->SUPER::update();
}

sub add_author {
	my $self = shift;

	my $author = shift;
	my $sort_index = shift;
	my $qualifier = shift;

	unless($sort_index) {
		croak "$self sort_index must be defined";
	}

	my $sql = 'insert into book_author_map (book_id, author_id, sort_index, qualifier) values (' . $self->id() . ', ' . $author->id() . ", $sort_index, '$qualifier')";
	$self->{dbh}->do($sql) or warn "$sql;\n";

	# invalidate the author cache
	delete $self->{author};

	return $author;
}

sub delete_author {
	my $self = shift;

	my $author = shift;

	my $sql = 'delete from book_author_map where book_id = ' . $self->id() . ' and author_id = ' . $author->id();
	$self->{dbh}->do($sql) or warn "$sql;\n";

	# invalidate the author cache
	delete $self->{author};

	return $author;
}

# Adds the given subject to the book
sub add_subject {
	my $self = shift;

	my $subject = shift;

	my $sql = 'insert into book_subject_map (book_id, subject_id) values (' . $self->id() . ', ' . $subject->id() . ')';
	$self->{dbh}->do($sql) or warn "$sql;\n";

	# invalidate the subject cache
	delete $self->{subject};

	return $subject;
}

sub delete_subject {
	my $self = shift;

	my $subject = shift;

	my $sql = 'delete from book_subject_map where book_id = ' . $self->id() . ' and subject_id = ' . $subject->id();
	$self->{dbh}->do($sql) or warn "$sql;\n";

	# invalidate the subject cache
	delete $self->{subject};

	return $subject;
}

# Returns an array reference containing the authors attached to this book
sub _author {
	my $self = shift;

	return Jaeger::Mapper->Map(
		table => 'book_author_map',
		idfield => 'book_id',
		id => $self->id(),
		field => 'author_id',
		'package' => 'Library::Author',
	);
}

# Returns an array reference containing the subjects attached to this book
sub _subject {
	my $self = shift;

	return Jaeger::Mapper->Map(
		table => 'book_subject_map',
		idfield => 'book_id',
		id => $self->id(),
		field => 'subject_id',
		'package' => 'Library::Subject',
	);
}
