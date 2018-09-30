#!/usr/bin/perl

# Create a site map xml file exposing all public, indexable urls for major
# search engines, avoiding the vagrancies of crawling.
#
# Protocol documentation:
# https://www.sitemaps.org/protocol.html
#
# Commentary:
# https://blog.codinghorror.com/the-importance-of-sitemaps/

use lib "$ENV{BCFS}/lib";

use Getopt::Long;
use Jaeger::Changelog;

my $outdir = '';
GetOptions('outdir=s' => \$outdir);

if($outdir) {
	chdir $outdir
		or die "Can't cd to $outdir: $!";
}

update_changelog_sitemap();

# TODO(jaeger): Implement a sitemap for photos, after changing the photo url
# scheme. 

exit;

sub update_changelog_sitemap {
	open SITEMAP, ">", "sitemap-changelog.xml"
		or die "Can't write to sitemap-changelog.xml: $!";

	print SITEMAP <<HERE;
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
HERE

	my $iter = Jaeger::Changelog->Prepare("status = 0 order by id");
	while(my $changelog = $iter->next()) {
		print SITEMAP "  <url>\n";
		print SITEMAP "    <loc>", $changelog->url(), "</loc>\n";
		print SITEMAP "    <changefreq>monthly</changefreq>\n";
		print SITEMAP "  </url>\n";
	}

	print SITEMAP <<HERE;
</urlset>
HERE

	close SITEMAP;
}
