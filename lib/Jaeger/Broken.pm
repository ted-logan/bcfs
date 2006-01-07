package		Jaeger::Broken;

#
# $Id: Broken.pm,v 1.1 2006-01-07 17:46:19 jaeger Exp $
#

# Broken page document -- serves a single static page for an entire
# directory tree

# 24 November 2005
# Ted Logan <jaeger@festing.org>

use strict;

use Apache::Constants qw(OK DECLINED REDIRECT);
use Apache::File;
use Apache::Cookie;
use Apache::Request;

sub handler {
	my $r = shift;

	warn "Filename requested is ", $r->filename(), "\n";

	# Still serve static documents that exist in the correct tree.
	# Does the file being requested exist, and is it not a directory?
	if(-f $r->filename()) {
		my $fh = Apache::File->new($r->filename());
		if($fh) {
			if((my $rc = $r->meets_conditions()) != OK) {
				return $rc;
			}

			# Set useful http/1.1 headers
			$r->set_content_length();
			$r->set_etag();
			$r->set_last_modified((stat $r->finfo)[9]);

			$r->send_http_header();
			$r->send_fd($fh);
			return OK;
		}
	}

	my $fh = Apache::File->new('/var/www/static.html');

	$r->send_http_header('text/html');
	$r->send_fd($fh);
	return OK;
}

1;
