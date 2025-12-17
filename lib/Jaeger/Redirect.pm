# Holds urls and redirect codes, making it possible to distinguish between 301
# moved permanently (used when urls are wrong or obsolete and there's a good
# new location), and 302 moved temporarily (used when redirecting to login urls
# or to to the current changelog).

package Jaeger::Redirect;

use strict;

use constant MOVED_PERMANENTLY => 301;
use constant MOVED_TEMPORARILY => 302;

sub new {
	my $package = shift;

	my $self = bless {}, $package;
	$self->{url} = shift;
	$self->{code} = shift || MOVED_TEMPORARILY;

	return $self;
}

sub http_status {
	my $self = shift;

	return $self->{code};
}

package Jaeger::ClientRedirect;

@Jaeger::ClientRedirect::ISA = qw(Jaeger::Base);

# Wraps a client-side meta redirect

sub new {
	my $package = shift;

	my $self = bless {}, $package;
	$self->{url} = shift;

	return $self;
}

sub http_status {
	my $self = shift;

	return 200;
}

sub meta {
	my $self = shift;

	return qq`<meta http-equiv="refresh" content="0;URL='$self->{url}'" />`;
}

1;
