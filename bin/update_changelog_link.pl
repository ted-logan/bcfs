#!/usr/bin/perl

use strict;

use lib "$ENV{BCFS}/lib";

use Jaeger::Changelog;
use Jaeger::User;

my $user = new Jaeger::User();
$user->{status} = 30;

my $iter = Jaeger::Changelog->Prepare();
while(my $changelog = $iter->next()) {
	# Look for links in the content. Check if each link references this
	# site. Check for updated links.
	print $changelog->id(), " ", $changelog->title(), " (",
		$changelog->url(), ")\n";
	# Make sure we're looking at the raw content from the database, before
	# applying the inline photo manipulations.
	my $content = $changelog->{content};
	while($content =~ /<\s*a\s+href="(.*?)"/igs) {
		my $href = $1;
		my $uri = undef;
		# Look for references to this site, and ignore the others
		if($href =~ m#^https?://jaeger\.festing\.org/#) {
			# Absolute link, it's probably in scope
			$uri = $href;
			$uri =~ s#^https?://jaeger\.festing\.org##;

		} elsif($href =~ m#^/# ) {
			# Relative link, it's probably in scope
			$uri = $href;
		}

		if(defined($uri)) {
			print "\t$uri\n";
			my $target = Jaeger::Changelog::Urimap($uri, $user);
			if(ref $target eq "Jaeger::Redirect") {
				print "\t-> ", $target->{url}, "\n";
			} else {
				print "\t-> $target\n";
			}
		}
	}
	print "\n";
}
