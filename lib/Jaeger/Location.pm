package	Jaeger::Location;

# 
# $Id: Location.pm,v 1.1 2003-01-10 06:54:21 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Wraps the location table, which specifies where a given photo was taken

# created  05 January 2003

use strict;

use Jaeger::Base;

@Jaeger::Location::ISA = qw(Jaeger::Base);

sub table {
	return 'location';
}
