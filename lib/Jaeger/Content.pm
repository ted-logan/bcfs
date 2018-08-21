package		Jaeger::Content;

#
# $Id: Content.pm,v 1.4 2006-02-17 04:09:43 jaeger Exp $
#

# Content-controlling code

# 28 October 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

@Jaeger::Content::ISA = qw(Jaeger::Base);

sub Navbar {
	my $package = shift;

	my $lf = Jaeger::Base::Lookfeel();

	my @content;

	push @content, '<li><a href="/photo.cgi">Photos</a></li>';
	push @content, '<li><a href="/flights.cgi">Flights</a></li>';
	push @content, '<li><a href="/yoda.cgi">Gas Mileage</a></li>';

	return $lf->linkbox(
		title => 'Content',
		links => join('', @content),
	);
}

1;
