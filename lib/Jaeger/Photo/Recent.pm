package Jaeger::Photo::Recent;

# Jaeger::Photo::Recent: Show recently-updated photos as the default view

use strict;

use Jaeger::Base;
use Jaeger::Photo;
use Jaeger::Photo::List;
use Jaeger::Photo::Year;
use Jaeger::User;

@Jaeger::Photo::Recent::ISA = qw(Jaeger::Photo::List);

sub _statusquery {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{statusquery} = "status <= $status and not hidden";
}

sub _photos {
	my $self = shift;
	$self->{photos} = [Jaeger::Photo->Select("mtime is not null and " . $self->statusquery() . " order by mtime desc limit 100")];
	return $self->{photos};
}

sub _title {
	my $self = shift;

	return $self->{title} = "Recent photos"
}

sub html {
	my $self = shift;

	my $year = new Jaeger::Photo::Year;

	my $html = $self->SUPER::html();

	return $year->yearlist() . $html . $year->yearlist();
}

sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL . "photo/";
}

1;
