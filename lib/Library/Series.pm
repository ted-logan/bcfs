package	Library::Series;

# 
# $Id: Series.pm,v 1.1 2003-12-01 02:37:42 jaeger Exp $
#
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Wraps the 'series' table

# created  27 November 2003

use strict;

use Jaeger::Base;

@Library::Series::ISA = qw(Jaeger::Base);

use Library::Book;

sub table {
	return 'series';
}
