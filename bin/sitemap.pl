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
use Jaeger::Comment;
use Jaeger::Photo;

my $outdir = '';
GetOptions('outdir=s' => \$outdir);

if($outdir) {
	chdir $outdir
		or die "Can't cd to $outdir: $!";
}

update_sitemap(
	"sitemap-changelog.xml",
	Jaeger::Changelog->Prepare("status = 0 order by id"),
	Jaeger::Comment->Prepare("status = 0 order by id"),
);

update_sitemap(
	"sitemap-photo.xml",
	Jaeger::Photo->Prepare(
		"status = 0 and not hidden order by date, round, number")
);

exit;

sub update_sitemap {
	my $file = shift;
	my @iter = @_;

	open SITEMAP, ">", $file
		or die "Can't write to $file: $!";

	print SITEMAP <<HERE;
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
HERE

	foreach my $iter (@iter) {
		while(my $changelog = $iter->next()) {
			print SITEMAP "  <url>\n";
			print SITEMAP "    <loc>", $changelog->url(),
				"</loc>\n";
			print SITEMAP "    <changefreq>monthly</changefreq>\n";
			print SITEMAP "  </url>\n";
		}
	}

	print SITEMAP <<HERE;
</urlset>
HERE

	close SITEMAP;
}
