package Jaeger::User::List;

#
# $Id: List.pm,v 1.2 2006-02-18 22:43:55 jaeger Exp $
#

# Shows a list of users

# 24 August 2003
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::User;

@Jaeger::User::List::ISA = qw(Jaeger::Base);

#
# Display-relevant member functions
#

sub title {
	my $self = shift;

	return 'User List';
}

sub url {
	my $title = shift;

	return 'http://jaeger.festing.org/user.cgi';
}

# returns the html for this object
sub html {
	my $self = shift;

	my @html;

	my @users = sort {lc $a->{name} cmp lc $b->{name}} Jaeger::User->Select();

	foreach my $user (@users) {
		next unless $user->{status};
		push @html, $self->lf()->user_list_item(
			link => $user->link(),
			last_visit => $user->last_visit(),
		);
	}

	return $self->lf()->user_list(
		users => join('', @html),
	);
}

1;
