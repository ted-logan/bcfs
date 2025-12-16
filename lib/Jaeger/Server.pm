package Jaeger::Server;

use strict;

use Jaeger::Base;
use Jaeger::Changelog;
use Jaeger::Photo;

# install libhttp-server-simple-perl
use HTTP::Server::Simple::CGI;

use base qw(HTTP::Server::Simple::CGI);

sub handle_request {
	my ($self, $cgi) = @_;

	# TODO make sure we have a valid database connection
	Jaeger::Base::Pingdbh();

	# TODO clean up context, set global variables like $cgi
	$Jaeger::Base::Ids = ();
	$Jaeger::Base::Query = $cgi;

	# do something
	my $uri = $cgi->request_uri();

	warn "Serving request for $uri\n";

	my $page;

	if($uri =~ m"^/changelog") {
		$page = Jaeger::Changelog::Urimap($uri);
	} elsif($uri =~ m"^/photo" || $uri =~ m"^/photo.cgi") {
		$page = Jaeger::Photo::Urimap($uri);
	}

	warn "got a page: $page\n";

	if(ref($page) eq 'Jaeger::Redirect') {
		# Redirect to a different url.
		if($page->{code} == Jaeger::Redirect::MOVED_PERMANENTLY) {
			print $cgi->redirect(
				-uri => $page->{url},
				-status => '301 Moved Permanently');
		} else {
			print $cgi->redirect($page->{url});
		}
		return;
	}

	print $cgi->header(
		-type => 'text/html; charset=UTF-8',
		-status => $page->http_status(),
		#-cookie => Jaeger::Base::Lookfeel()->{cookies});
		);
	print Jaeger::Base::Lookfeel()->main($page);

}

sub print_banner {
	my $self = shift;

	print("Jaeger::Server starting up\n");
}

1;
