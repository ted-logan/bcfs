package Jaeger::Comment::Post;

#
# $Id: Post.pm,v 1.1 2003-11-03 04:05:41 jaeger Exp $
#

# Code to allow a user to post a comment

# 02 November 2003
# Ted Logan
# jaeger@festing.org

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::Comment::Post;

use Apache::Request;
use Carp;

@Jaeger::Comment::Post::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{request} = Apache::Request->new(shift);
	$self->{changelog} = shift;
	$self->{comment} = shift;

	if($self->{request}->param('response_to_id')) {
		$self->{comment} = Jaeger::Comment->new_id(
			$self->{request}->param('response_to_id')
		);
	}

	return $self;
}

#
# Display functions
#

sub html {
	my $self = shift;

	my $go = $self->{request}->param('go');

	my $reply_to = $self->{comment} ? $self->{comment} : $self->{changelog};

	if($go eq 'Submit') {
		# submit the comment
		my $comment = new Jaeger::Comment;
		$comment->{user} = Jaeger::User->Login();
		$comment->{changelog} = $self->{changelog};
		$comment->{response_to} = $self->{comment};
		$comment->{title} = $self->{request}->param('title');
		$comment->{body} = $self->{request}->param('body');

		if($comment->update()) {
			return "Comment sucessfully created.";
		} else {
			return "Something went wrong.";
		}

		# now, redirect to the comment itself

	} elsif($go eq 'Preview') {
		# preview the comment
		return $reply_to->html() . $self->lf()->comment_preview(
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			title => $self->{request}->param('title'),
			body => $self->{request}->param('body'),
		) . $self->lf()->comment_edit(
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			header => $self->title(),
			title => $self->{request}->param('title'),
			body => $self->{request}->param('body'),
		);
		
	} else {
		return $reply_to->html() . $self->lf()->comment_edit(
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			header => $self->title(),
		);
	}

	return undef;
}

sub _title {
	my $self = shift;

	if($self->{comment}) {
		return $self->{title} = "Comment on comment \"" .
			$self->{comment}->title() . "\"";
	} else {
		return $self->{title} = "Comment on changelog \"" .
			$self->{changelog}->title() . "\"";
	}
}

=for later
sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL . 'changelog/comment/' .
		$self->id() . '.html';
}
=cut

1;
