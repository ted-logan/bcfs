package Jaeger::Login;

use strict;

@Jaeger::Login::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{redirect} = shift;

	return $self;
}

sub _http_status {
	my $self = shift;

	return $self->{http_status} = 401;
}

sub _title {
	my $self = shift;

	return $self->{title} = 'Login';
}

sub _html {
	my $self = shift;

	my $redirect = $self->{redirect};
	if(ref $redirect) {
		$redirect = $redirect->url();
	}

	return $self->lf()->login(redirect => $redirect);
}
