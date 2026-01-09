package Jaeger::Server;

use strict;

use Jaeger::Base;
use Jaeger::Changelog;
use Jaeger::Photo;

# install libhttp-server-simple-perl
use HTTP::Server::Simple::CGI;
use HTTP::Status qw(status_message);
use Log::Any qw($log);

use base qw(HTTP::Server::Simple::CGI);

# I am setting this up to work with an Apache reverse proxy:
# https://httpd.apache.org/docs/2.4/howto/reverse_proxy.html
#
# To do this I need apache modules enabled:
#
# $ a2enmod proxy
# $ a2enmod proxy_http
#
# Inside my VirtualHost I have these proxy directives:
#
#       ProxyPass "/changelog" "http://localhost:8080/changelog"
#       ProxyPass "/photo" "http://localhost:8080/photo"
#       ProxyPass "/photo.cgi" "http://localhost:8080/photo.cgi"

sub handle_request {
	my ($self, $cgi) = @_;

	# TODO make sure we have a valid database connection
	Jaeger::Base::Pingdbh();

	my $lf = Jaeger::Base::Lookfeel();

	# TODO clean up context, set global variables like $cgi
	$Jaeger::Base::Ids = ();
	$Jaeger::Base::Query = $cgi;
	$Jaeger::User::Current = 0;
	$lf->{cookies} = undef;

	my $user = Jaeger::User->Login();

	# do something
	my $uri = $cgi->request_uri();

	$log->debug("Serving request for $uri");

	local $log->context->{uri} = $uri;

	my $page;

	if($uri =~ m"^/changelog") {
		$page = Jaeger::Changelog::Urimap($uri, $user);
	} elsif($uri =~ m"^/photo" || $uri =~ m"^/photo.cgi") {
		$page = Jaeger::Photo::Urimap($uri, $user);
	}

	$log->debug("got a page: $page");

	my $status = $page->http_status() || 200;
	my $message = status_message($status);
	$log->info("Response is $status $message");
	print "HTTP/1.1 $status $message\r\n";
	if(ref($page) eq 'Jaeger::Redirect') {
		print "Location: $page->{url}\r\n";
		print "\r\n";
		return;
	}

	print $cgi->header(
		-type => 'text/html; charset=UTF-8',
		-cookie => $lf->{cookies});

	if(ref($page) eq 'Jaeger::Photo') {
		if($lf->ismobilebrowser()) {
			print $lf->photo_main_mobile($page);
		} else {
			print $lf->photo_main($page);
		}
	} elsif(ref($page) =~ /Jaeger::Photo/) {
		print $lf->photo_list_main($page);
	} else {
		print $lf->main($page);
	}

}

sub print_banner {
	my $self = shift;

	$log->info("Jaeger::Server starting up");
}

1;
