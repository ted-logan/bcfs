package Jaeger::User::Create;

#
# $Id: Create.pm,v 1.3 2003-11-05 04:16:28 jaeger Exp $
#

# Allows the creation of new users

# 24 August 2003
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::User;

@Jaeger::User::Create::ISA = qw(Jaeger::Base);

use MIME::Lite;

#
# Display-relevant member functions
#

sub _step {
	my $self = shift;

	unless($self->{step}) {
		$self->{step} = $self->query()->param('step');
	}
	unless($self->{step}) {
		$self->{step} = 0;
	}

	return $self->{step};
}

sub title {
	my $self = shift;

	return 'Create user';
}

# returns the html for this object
sub html {
	my $self = shift;

	# the error message, if any
	my $message;

	# Performs whatever steps are necessary
	if($self->step()) {
		eval "\$self->step" . $self->step() . "()";
		if($@) {
			$message = $@;
		}
	}

	unless($message) {
		$self->{step}++;
	}

	$self->{message} = $message;

	my $html = eval "\$self->html" . $self->step() . "()";
	if($@) {
		die $@;
	}
	return $html;
}

#
# The code that actually adds the user
#

sub html1 {
	my $self = shift;

	my $q = $self->query();

	return $self->lf()->user_create_step1(
		message => $self->{message},
		login => $q->param('login'),
		name => $q->param('name'),
		email => $q->param('email'),
	);
}

# this step verifies the user's input, inserts her into the database, and
# sends her an e-mail
sub step1 {
	my $self = shift;

	my $q = $self->query();

	# verify that all of the inputs are filled
	my $login = $q->param('login');
	my $name = $q->param('name');
	my $email = $q->param('email');

	my $user = $self->step1_adduser(
		login => $login,
		name => $name,
		email => $email,
	);

	# send the user e-mail
	my $msg = new MIME::Lite(
		From	=> 'New jaegerfesting account <jaeger@festing.org>',
		To	=> $email,
		BCC	=> 'jaeger@festing.org',
		Subject	=> 'New jaegerfesting account',
		Data	=> $self->lf()->user_create_email(%$user)
	);

	$msg->send();

	# all done
}

sub step1_adduser {
	my $self = shift;

	my %user = @_;

	unless($user{login} && $user{name} && $user{email}) {
		die "All fields must be filled.\n";
	}

	# check that the login doesn't already exist
	if(Jaeger::User->Count(login => $user{login})) {
		die "The login \"$user{login}\" is already taken.\n";
	}

	# check that the name/alias doesn't already exist
	if(Jaeger::User->Count(name => $user{name})) {
		die "Someone is already using the name \"$user{name}\".\n";
	}

	# pick a random password (for e-mail verification)
	my $password = do {
		my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
		my @password;

		for(my $i = 0; $i < 8; $i++) {
			push @password, $chars[rand @chars];
		}

		join '', @password;
	};

	# insert the user
	my $user = new Jaeger::User;
	$user->login($user{login});
	$user->password($password);
	$user->name($user{name});
	$user->email($user{email});
	$user->status(defined($user{status}) ? $user{status} : 0);

	$user->update();

	return $user;
}

sub html2 {
	my $self = shift;

	return $self->lf()->user_create_step2(
		email => $self->query()->param('email')
	);
}

sub step2 {
	my $self = shift;

	my $user = Jaeger::User->Login();

	# increment the user's status
	$user->{status} = 10;
	$user->{signup} = 'now()';
	$user->update();
}

sub html3 {
	my $self = shift;

	my $user = Jaeger::User->Login();

	return $self->lf()->user_create_step3(
		change => $self->lf()->user_edit(%$user),
	);
}

1;
