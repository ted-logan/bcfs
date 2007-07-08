package	Jaeger::Vehicle;

# 
# $Id: Vehicle.pm,v 1.1 2007-07-08 19:02:05 jaeger Exp $
#
# Copyright (c) 2007 Ted Logan (jaeger@festing.org)

# Wraps the vehicle table

# created  08 July 2007

use strict;

use Jaeger::Base;

@Jaeger::Vehicle::ISA = qw(Jaeger::Base);

sub table {
	return 'vehicle';
}
