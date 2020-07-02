package Jaeger::Session;

use strict;

use Jaeger::Base;

@Jaeger::Session::ISA = qw(Jaeger::Base);

use Carp;
use POSIX;

sub table {
	return 'session';
}

sub update {
	my $self = shift;

	$self->SUPER::update();
}

sub Create {
	my $package = shift;

	my $user = shift;

	my $self = bless {
		user_id => $user->id(),
		expires => POSIX::strftime("%FT%T%z", localtime (time + 31*24*3600)),
	}, $package;

	# Generate a random, 128-bit number, encoded into 32 hex digits
	# (Code borrowed from BMAS::Session, dated 6 September 2002)
	do {
		$self->{key} = '';
		for(my $i = 0; $i < 32; $i++) {
			$self->{key} .= sprintf '%01x', int(rand(16));
		}
		# the odds of getting two identical keys are astronomically
		# small (say, 2^-128), but if I don't add this loop, we will
		# inevetibally get a matching one the first time a customer
		# tries to use it
	} while($package->Count(key => $self->{key}));

	warn "Jaeger::Session->Create(): Created key $self->{key} for $user->{login}\n";

	return $self;
}

1;
