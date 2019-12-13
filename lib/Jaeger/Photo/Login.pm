package Jaeger::Photo::Login;

use strict;

@Jaeger::Photo::Login::ISA = qw(Jaeger::Base);

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

	return $self->lf()->photo_login(redirect => $self->{redirect}->url());
}
