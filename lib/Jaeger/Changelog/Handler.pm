package		Jaeger::Changelog::Handler;

#
# $Id: Changelog.pm,v 1.33 2007-06-30 18:33:25 jaeger Exp $
#

# mod_perl handler for changelogs.
#
# This is placed in a separate source file to provide some level of segregation
# between model, view, and controller. (Though the division isn't as strict
# as one might like, this handler is the controller, Jaeger::Changelog is the
# model, and Jaeger::Lookfeel and the look-and-feel templates are the view.)

# 4 September 2008
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Changelog;
use Jaeger::Changelog::Tag;
use Jaeger::Lookfeel;
use Jaeger::User;
use Jaeger::Comment;
use Jaeger::Comment::Post;

use Apache::Constants qw(OK DECLINED REDIRECT);
use Apache2::Request;
use Apache2::Cookie;

#
# mod_perl handler for changelogs (so we can get urls that don't end in
# .cgi so Google will index)
#
sub handler {
	my $r = shift;

	# clear the global cache of object ids in case any of them changed
	#
	# (There should be a better way to do this, to only the objects
	# that actually changed, but this is the simplest for now.)
	%Jaeger::Base::Ids = ();

	# does the file being requested exist, and is it not a directory?
	if(-f $r->filename()) {
		# TODO This doesn't seem to send the relevant headers for
		# client-side caching
		return $r->sendfile($r->filename());
	}

	$Jaeger::Base::Query = Apache2::Request->new($r);

	# Are we a logged-in user?
	my $user = undef;
	my $jar = Apache2::Cookie::Jar->new($r);
	if($jar->cookies('jaeger_login') && $jar->cookies('jaeger_password')) {
		$user = Jaeger::User->Login(
			$jar->cookies('jaeger_login')->value(),
			$jar->cookies('jaeger_password')->value() 
		);
		if($user) {
			# send updated cookies
			$user->cookies();
		}
	} else {
		$Jaeger::User::Current = undef;
	}

	my $changelog = Jaeger::Changelog::Urimap($r->uri(), $user);

	# Do we want to redirect to somewhere else?
	unless(ref $changelog) {
		$r->headers_out->set(Location => $changelog);

		return REDIRECT;
	}

	# If we're Googlebot, log this view.
	# 
	# (Don't use the normal method, which would present the bot with
	# the "you're now logged in" message and other stuff.)
	my $ua = $r->headers_in->get('User-Agent');
	if($ua =~ /googlebot/i) {
		my $googlebot = Jaeger::User->Select(login => 'googlebot');
		$googlebot->log_access($changelog);
		$googlebot->update_last_visit();
	}

	# Store the user's browser in the database
	if($user) {
		$user->{last_browser} = $ua;
		$user->update();
	}

	$r->send_http_header('text/html; charset=UTF-8');

	print Jaeger::Base::Lookfeel()->main($changelog);

	# Clean up after the logged-in user, since we're doing the sneaky
	# mod_perl thing

	$Jaeger::User::Current = 0;
	$Jaeger::Base::Query = undef;
	$Jaeger::Base::Pgdbh->disconnect();
	$Jaeger::Base::Pgdbh = undef;
	$Jaeger::Base::Lookfeel = undef;
	%Jaeger::Base::Ids = ();

	return OK;
}

1;
