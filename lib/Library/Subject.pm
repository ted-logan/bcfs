package	Library::Subject;

# 
# $Id: Subject.pm,v 1.1 2003-12-01 02:37:42 jaeger Exp $
#
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Wraps the 'subject' table

# created  27 November 2003

use strict;

use Jaeger::Base;
use Jaeger::Mapper;

@Library::Subject::ISA = qw(Jaeger::Base);

use Library::Book;

sub table {
	return 'subject';
}

# Returns a hash reference containing the books containing this subject
sub _books {
	my $self = shift;

	return Jaeger::Mapper->Map(
		table => 'book_subject_map',
		idfield => 'subject_id',
		id => $self->id(),
		field => 'book_id',
		'package' => 'Library::Book',
	);
}
