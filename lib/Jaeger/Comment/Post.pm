package Jaeger::Comment::Post;

#
# $Id: Post.pm,v 1.5 2004-02-28 21:07:50 jaeger Exp $
#

# Code to allow a user to post a comment

# 02 November 2003
# Ted Logan
# jaeger@festing.org

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::Comment::Post;

use Carp;

@Jaeger::Comment::Post::ISA = qw(Jaeger::Base);

sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	my $q = $self->query();

	$self->{changelog} = shift;
	$self->{comment} = shift;

	if($q->param('response_to_id')) {
		$self->{comment} = Jaeger::Comment->new_id(
			$q->param('response_to_id')
		);
	}

	return $self;
}

#
# Display functions
#

sub html {
	my $self = shift;

	my $go = $self->query()->param('go');

	warn "Go is $go\n";

	my $reply_to = $self->{comment} ? $self->{comment} : $self->{changelog};

	my $title = $self->query()->param('title');
	$title =~ s/<.*?>//g;
	$title =~ s/"/&quot;/g;

	if($go eq 'Submit') {
		# submit the comment
		my $comment = new Jaeger::Comment;
		$comment->{user} = Jaeger::User->Login();
		$comment->{changelog} = $self->{changelog};
		$comment->{response_to} = $self->{comment};
		$comment->{title} = $title;
		$comment->{status} = $self->query()->param('status');
		$comment->{body} = Jaeger::Comment::Post->Allowed(
			Jaeger::Comment::Post->Unescape(
				$self->query()->param('body')
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
			$self->query()->param('body')
		);

		return $reply_to->html() . $self->lf()->comment_preview(
			uri => $self->query()->uri(),
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			title => $title,
			body => $body,
			status => $self->query()->param('status'),
		) . $self->lf()->comment_edit(
			uri => $self->query()->uri(),
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			header => $self->title(),
			title => $title,
			body => $body,
			visibility => $self->visibility($self->query()->param('status')),
		);
		
	} else {
		return $reply_to->html() . $self->lf()->comment_edit(
			uri => $self->query()->uri(),
			changelog_id => $self->{changelog}->id(),
			response_to_id => $self->{comment} ? $self->{comment}->id() : "",
			header => $self->title(),
			visibility => $self->visibility(),
		);
	}

	return undef;
}

sub visibility {
	my $self = shift;

	my $stat = shift;

	my $level;

	if($self->{comment}) {
		$level = $self->{comment}->{status};
	} else {
		$level = $self->{changelog}->{status};
	}

	my $user = Jaeger::User->Login();

	my @html;

	foreach my $status (sort {$a <=> $b} keys %Jaeger::Changelog::Status) {
		next if $status < $level;
		next if $status > $user->{status};
		push @html, '<option ';
		if($stat == $status) {
			push @html, 'selected ';
		}
		push @html, qq'value="$status">$Jaeger::Changelog::Status{$status}</option>\n';
	}

	return join('', @html);
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
