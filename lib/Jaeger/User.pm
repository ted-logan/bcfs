package	Jaeger::User;

# 
# $Id: User.pm,v 1.5 2003-11-01 17:50:55 jaeger Exp $
#
# Copyright (c) 2002 Buildmeasite.com
# Copyright (c) 2003 Ted Logan (jaeger@festing.org)

# Allows users to log in and do fun and useful stuff

# 08 May 2003
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;

@Jaeger::User::ISA = qw(Jaeger::Base);

use Jaeger::User::List;

use Carp;

# What the various status codes mean
%Jaeger::User::Status = (
	0 => 'Unverified',	# Still waiting to confirm e-mail address;
				# can't actually do anything yet.

	10 => 'Normal',		# Most users; can post, but can't see hidden
				# content.

	20 => 'Elite',		# The select group of people who have access
				# to hidden changelogs.

	30 => 'God',		# Jaeger himself.
);

#
# Data-relevant member functions
#

sub table {
	return 'jaeger_user';
}

# make sure all of the vital parameters are set
sub update {
	my $self = shift;

	# complain unless a login is given
	unless($self->{login}) {
		carp "Jaeger::User->update(): login must be set";
		return undef;
	}

	# complain unless status is set
	unless(defined $self->{status}) {
		carp "Jaeger::User->update(): status must be set";
		return undef;
	}

	# complain unless password is set
	unless($self->{password}) {
		carp "Jaeger::User->update(): password must be set";
		return undef;
	}

	# complain unless the e-mail is set
	unless($self->{email}) {
		carp "Jaeger::User->update(): email must be set";
		return undef;
	}

	$self->SUPER::update();
}

sub columns {
	my $self = shift;

	my @columns = $self->SUPER::columns();

	unless($self->{last_visit}) {
		@columns = grep !/last_visit/, @columns;
	}

	return @columns;
}

# change the crypt()ed password
sub password {
	my $self = shift;

	my $password = shift;

	return unless $password;

	# come up with some brilliant salt
	my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];

	$self->{password} = crypt($password, $salt);

	$self->{plain_password} = $password;
}

# check the crypt()ed password
sub check_password {
	my $self = shift;

	my $password = shift;

	return unless $password;

	$self->{plain_password} = $password;

	return crypt($password, $self->{password}) eq $self->{password};
}

sub update_last_visit {
	my $self = shift;

	my $sql = "select now()";
	my $sth = $self->dbh()->prepare($sql);
	$sth->execute();

	$self->{last_visit} = ($sth->fetchrow_array())[0];

	$self->update();
}

#
# (Insert intelligent comment here)
#

# The current user. Zero if not yet determined; undef if not logged in
#
# (If we happen to be using mod_perl, this should be reset at the end of
# each request is processed by the request processor itself.)
$Jaeger::User::Current = 0;

# Returns the current user, logging him in if necessary
sub Login {
	my $package = shift;

	if(@_ || (defined($Jaeger::User::Current) && $Jaeger::User::Current == 0)) {
		$Jaeger::User::Current = $package->_Login(@_);
	}

	return $Jaeger::User::Current;
}

# Does the heavy lifting of actually logging in a user
sub _Login {
	my $package = shift;

	my $login;
	my $password;

	if(@_) {
		# the login and password were specified by the caller
		$login = lc shift;
		$password = shift;

	} else {
		# grab the login and password from cookies
		my $q = $package->Query();

		$login = lc $q->cookie('jaeger_login');
		$password = $q->cookie('jaeger_password');
	}

	my $user = $package->Select(login => $login);

	if($user) {
		# check the user's password
		if($user->check_password($password)) {
			# all ok

			# update the user's login date
			$user->update_last_visit();

			return $user;
		} else {
			# invalid password
			return undef;
		}
	} else {
		# user not found
		return undef;
	}
}

# sets or clears a user's cookies
sub cookies {
	my $self = shift;

	my $q = $self->query();

	push @{$self->lf()->{cookies}}, $q->cookie(
		-name => 'jaeger_login',
		-value => $self->{login},
		-expires => '+31d',
	);

	push @{$self->lf()->{cookies}}, $q->cookie(
		-name => 'jaeger_password',
		-value => $self->{plain_password},
		-expires => '+31d',
	);
}

# register the fact that this user accessed the resource in question
sub log_access {
	my $self = shift;

	my $object = shift;

	my $sql;

	if(ref($object) eq 'Jaeger::Changelog' && $object->id()) {
		$sql = "insert into user_changelog_view (changelog_id, user_id) values (" . $object->id() . ", " . $self->id() . ")";
	} elsif(ref($object) eq 'Jaeger::Comment' && $object->id()) {
		$sql = "insert into user_comment_view (comment_id, user_id) values (" . $object->id() . ", " . $self->id() . ")";
		
	} else {
		# Whatever was passed to us we don't support
		return undef;
	}

	$self->dbh()->do($sql)
		or warn "$sql;\n";
}

#
# Display-relevant member functions
#

sub _title {
	my $self = shift;

	return "View User: $self->{name}";
}

# returns the html for this object
sub html {
	my $self = shift;

	return $self->lf()->user_view(%$self);
}

sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL .
		"user.cgi?user=$self->{login}";
}

sub _link {
	my $self = shift;

	return $self->{link} = '<a href="' . $self->url() . qq'">$self->{name}</a>';
}

1;
