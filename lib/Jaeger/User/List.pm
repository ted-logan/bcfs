package Jaeger::User::List;

#
# $Id: List.pm,v 1.1 2003-08-25 03:16:54 jaeger Exp $
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

	push @html, $self->lf()->user_list();

	my @users = sort {$a->{name} cmp $b->{name}} Jaeger::User->Select();

	foreach my $user (@users) {
		next unless $user->{status};
		push @html, $self->lf()->user_list_item(
			link => $user->link(),
			last_visit => $user->last_visit(),
		);
	}

	return join '', @html;
}

1;
