package	Jaeger::UserBox;

# 
# $Id: UserBox.pm,v 1.1 2004-11-12 23:12:33 jaeger Exp $
#
# Copyright (c) 2004 Ted Logan (jaeger@festing.org)

# Allows users to have their own boxes

# 16 September 2004
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;

@Jaeger::UserBox::ISA = qw(Jaeger::Base);

use Carp;

#
# Data-relevant member functions
#

sub table {
	return 'user_box';
}

# make sure all of the vital parameters are set
sub update {
	my $self = shift;

	unless($self->{user_id}) {
		if($self->{user}) {
			$self->{user_id} = $self->{user}->id();
		} else {
			carp "Jaeger::UserBox->update(): user must be set";
		}
	}

	unless($self->{title}) {
		carp "Jaeger::UserBox->update(): title must be set";
	}

	unless($self->{url}) {
		carp "Jaeger::UserBox->url(): title must be set";
	}

	$self->SUPER::update();
}

1;
