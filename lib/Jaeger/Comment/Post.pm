package Jaeger::Comment::Post;

#
# $Id: Post.pm,v 1.3 2003-12-04 22:41:07 jaeger Exp $
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

	my $title = $self->{request}->param('title');
	$title =~ s/<.*?>//g;
	$title =~ s/"/&quot;/g;

	if($go eq 'Submit') {
		# submit the comment
		my $comment = new Jaeger::Comment;
		$comment->{user} = Jaeger::User->Login();
		$comment->{changelog} = $self->{changelog};
		$comment->{response_to} = $self->{comment};
		$comment->{title} = $title;
		$comment->{body} = Jaeger::Comment::Post->Allowed(
			Jaeger::Comment::Post->Unescape(
				$self->{request}->param('body')
			)
		);

		if($comment->update()) {
			return "Comment sucessfully created.";
		} else {
			return "Something went wrong.";
		}

		# now, redirect to the comment itself

	} elsif($go eq 'Preview') {
		# preview the comment
		my $body = Jaeger::Comment::Post->Allowed(
			$self->{request}->param('body')
		);

		return $reply_to->html() . $self->lf()->comment_preview(
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			title => $title,
			body => $body,
		) . $self->lf()->comment_edit(
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			header => $self->title(),
			title => $title,
			body => $body,
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

#
# Strip unallowed html
#

my %allowed_html = map {$_, 1}
	qw(a b blockquote br em i li p ol small strong ul);

sub Allowed {
	my $package = shift;

	my $body = shift;

	$body =~ s/(<\s*\/?\s*(\w*).*?>)/$allowed_html{lc $2} ? $1 : ''/seg;

	return $body;
}

#
# escape and un-escape special charcters so the browser doesn't choke
#

sub Escape {
	my $package = shift;

	my $body = shift;

	$body =~ s/([&<>"\r\n\\])/sprintf "\\0x%02x", ord $1/ge;

	return $body;
}

sub Unescape {
	my $package = shift;

	my $body = shift;

	$body =~ s/\\0x(\w\w)/chr hex $1/ge;

	return $body;
}

=for later
sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL . 'changelog/comment/' .
		$self->id() . '.html';
}
=cut

1;
