package Jaeger::Comment;

#
# $Id: Comment.pm,v 1.6 2006-02-17 16:57:56 jaeger Exp $
#

# Code to show and create user comments

# 31 August 2003
# Ted Logan
# jaeger@festing.org

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

use Jaeger::Comment::Post;

use Jaeger::Changelog;
use Jaeger::User;

use Carp;

@Jaeger::Comment::ISA = qw(Jaeger::Base);

#
# Data-control functions
#

sub table {
	return 'comment';
}

sub update {
	my $self = shift;

	unless($self->{changelog_id}) {
		if($self->{changelog}) {
			$self->{changelog_id} = $self->{changelog}->id();
		} else {
			carp "Jaeger::Comment->update(): changelog must be set";
			return undef;
		}
	}

	unless($self->{user_id}) {
		if($self->{user}) {
			$self->{user_id} = $self->{user}->id();
		} else {
			carp "Jaeger::Comment->update(): user must be set";
			return undef;
		}
	}

	if(!$self->{response_to_id} && $self->{response_to}) {
		$self->{response_to_id} = $self->{response_to}->id();
	}

	unless($self->{title}) {
		carp "Jaeger::Comment->update(): title must be set";
		return undef;
	}

	unless($self->{body}) {
		carp "Jaeger::Comment->update(): body must be set";
		return undef;
	}

	$self->SUPER::update();
}

sub columns {
	my $self = shift;

	my @columns = $self->SUPER::columns();

	unless($self->{date}) {
		@columns = grep !/date/, @columns;
	}

	return @columns;
}

sub _changelog {
	my $self = shift;

	return $self->{changelog} =
		Jaeger::Changelog->new_id($self->{changelog_id});
}

sub _user {
	my $self = shift;

	return $self->{user} =
		Jaeger::User->new_id($self->{user_id});
}

sub _response_to {
	my $self = shift;

	if($self->{response_to_id}) {
		return $self->{response_to} =
			Jaeger::Comment->new_id($self->{response_to_id});
	} else {
		return $self->{response_to} = undef;
	}
}

# Returns the comments that are direct responses to this comment
sub _responses {
	my $self = shift;

	return $self->{responses} = [grep {$_->{response_to_id} == $self->id()}
		@{$self->changelog()->comments()}
	];

#	return $self->{responses} = [Jaeger::Comment->Select(
#		response_to_id => $self->id()
#	)];
}

sub responses_list_html {
	my $self = shift;

	my @html;

	push @html, $self->lf()->comment_link(
		link => $self->link(),
		user => $self->user()->link(),
		date => $self->date(),
	);

	my @responses = sort {$a->date() cmp $b->date()}
		@{$self->responses()};
	foreach my $response (@responses) {
		push @html, "<ul>\n";
		push @html, $response->responses_list_html();
		push @html, "</ul>\n";
	}

	return @html;
}

#
# Return a navigation bar containing recent comments
#
sub Navbar {
	my $package = shift;

	my $lf = Jaeger::Base::Lookfeel();

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	my @links;

	my @comments = $package->Select("status <= $level and date > now() + '-1 week' order by date desc limit 8");
	foreach my $comment (@comments) {
		push @links, $lf->comment_link(
			link => $comment->link(),
			user => $comment->user()->link(),
			date => $comment->date(),
		);
	}

	unless(@comments) {
		push @links, "<i>(No recent comments)</i>\n";
	}

	return $lf->linkbox(
		url => '/changelog',
		title => 'Comments',
		links => join('', @links)
	);
}

#
# Display functions
#

sub html {
	my $self = shift;

	my $user = Jaeger::User->Login();
	if($user) {
		$user->log_access($self);
	}

	my $navigation = $self->changelog()->comment_list_html($self);
	if($user) {
		# show the users who have viewed the comment
		$navigation = '<p>These people have read this comment: ' . join(', ', map {$_->link()} sort {$a->{name} cmp $b->{name}} @{$self->user_views()}) . "</p>\n" . $navigation;
	}

	return $self->lf()->comment(
		id => $self->id(),
		title => $self->title(),
		user => $self->user()->link(),
		visibility => $Jaeger::Changelog::Status{$self->{status}},
		date => $self->date(),
		content => $self->body(),
		navigation => $navigation
	);
}

sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL . 'changelog/comment/' .
		$self->id() . '.html';
}

sub _link {
	my $self = shift;

	return $self->{link} = '<a href="' . $self->url() . '">' . $self->title() . '</a>';
}

# returns the identities of those who have viewed this comment
sub _user_views {
	my $self = shift;

	return [] unless $self->id();

	my $where = 'id in (select distinct user_id from user_comment_view where comment_id = ' . $self->id() . ')';

	return $self->{user_views} = [Jaeger::User->Select($where)];
}


1;
