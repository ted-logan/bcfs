package Jaeger::User::Edit;

#
# $Id: Edit.pm,v 1.2 2003-08-26 23:55:05 jaeger Exp $
#

# Allows the creation of new users

# 24 August 2003
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::User;

@Jaeger::User::Edit::ISA = qw(Jaeger::Base);

#
# Display-relevant member functions
#

sub title {
	my $self = shift;

	return 'Edit Thyself';
}

# returns the html for this object
sub html {
	my $self = shift;

	my $user = Jaeger::User->Login();

	unless($user) {
		$self->redirect('http://jaeger.festing.org/login.cgi');
	}

	# the error message, if any
	my $message;

	if($self->query()->param('go') eq 'yep') {
		$message = $self->update();
	}

	return $self->lf()->user_edit(message => $message, %$user);
}

# this step verifies the user's input, and updates the database
sub update {
	my $self = shift;

	my $q = $self->query();

	my $user = Jaeger::User->Login();

	# verify that all of the inputs are filled
	my $name = $q->param('name');
	my $email = $q->param('email');

	unless($name && $email) {
		return "The name and e-mail must be filled.\n";
	}

	# is the password changed?
	my $pw1 = $q->param('password1');
	my $pw2 = $q->param('password2');

	if($pw1 && $pw2) {
		if($pw1 eq $pw2) {
			$user->password($pw1);
		} else {
			return "The passwords must match.\n";
		}
	} elsif($pw1 || $pw2) {
		return "The password must be typed twice to confirm it.\n";
	}

	# copy the remaining info
	$user->name($q->param('name'));
	$user->email($q->param('email'));
	$user->webpage($q->param('webpage'));
	$user->about($q->param('about'));

	# update the user
	$user->update();

	$user->cookies();

	# all done
	return "User info updated.";
}

1;
