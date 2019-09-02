package Jaeger::PageRedirect;

# Database-driven permanent redirects to new locations for a resource

use strict;

use Jaeger::Base;

@Jaeger::PageRedirect::ISA = qw(Jaeger::Base);

sub table {
	return 'redirect';
}

1;
