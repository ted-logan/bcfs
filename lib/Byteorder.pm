package Byteorder;

# $Id: Byteorder.pm,v 1.1 2002-05-19 22:54:05 jaeger Exp $
#
# implements functions to convert between network and host byteorder
#
# 11 February 2002
# Ted Logan

use strict;

use Exporter;
@Byteorder::ISA = qw(Exporter);
@Byteorder::EXPORT_OK = qw(ntohl);

sub ntohl {
	my $rv = 0;
	foreach my $n (map {ord} split //, shift) {
		$rv = ($rv << 8) + $n;
	}
	return $rv;
}

1;
