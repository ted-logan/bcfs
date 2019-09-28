package Jaeger::Photo::Notfound;

use strict;

@Jaeger::Photo::Notfound::ISA = qw(Jaeger::Base);

sub _http_status {
	my $self = shift;

	return $self->{http_status} = 404;
}

sub _title {
	my $self = shift;

	return $self->{title} = 'Not found';
}

sub _html {
	my $self = shift;

	return $self->lf()->photo_not_found(%$self);
}
