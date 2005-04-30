#!/usr/bin/perl

# $Id: avgo.pl,v 1.3 2005-04-30 18:05:51 jaeger Exp $

# Plain-text output of jaegerfesting for avantgo chanel
# 09 September 2000

use lib '/home/jaeger/programming/webpage/lib';

use strict;

use Jaeger::Changelog;
use CGI;

print "content-type: text/html\n\n";

my $q = new CGI;

if(my $id = $q->param('changelog')) {
        my $changelog = Jaeger::Changelog->new_id($id);

        print "<html><head><title>", $changelog->title(), "</title></head>\n";
        print "<h2>", $changelog->title(), "</h2>\n";
	print "<h3>", $changelog->time_begin(), "</h3>\n";
        my $content = $changelog->content();
        # to simplify things, strip the <a ...> tags
        $content =~ s/<\/?a.*?>//g;
        print "$content\n";
        print "<hr>\n";

	# Show the changelog's comments
	my $comments = $changelog->comments();
	if(@$comments) {
		foreach my $comment (sort {$a->{date} cmp $b->{date}} @$comments) {
			print "<h3>Comment: ", $comment->user()->name(), ": ",
				$comment->title(), "</h3>\n";
			print "<h4>", $comment->date(), "</h4>\n";
			my $content = $comment->body();
			$content =~ s/<\/?a.*?>//g;
			print "$content\n";
		}
		print "<hr>\n";
	}

        if(my $prev = $changelog->prev()) {
                print "&lt;- <a href=\"avgo.pl?changelog=", $prev->id(), "\">", $prev->title(), "</a> | ";
        }
        print "<a href=\"avgo.pl\">jaegerfesting</a>";
        if(my $next = $changelog->next()) {
                print " | <a href=\"avgo.pl?changelog=", $next->id(), "\">", $next->title(), "</a> -&gt;\n";
        }
} else {
        my @changelogs = Jaeger::Changelog->Select(
		'1=1 order by time_begin desc limit 10'
	);
=for later	
        my $chatterbox = new Shared::Chatter;
        my @chatter = $chatterbox->recent("timestamp > now() + '-2d'", 10);
=cut

        print "<html><head><title>jaegerfesting: Mobile</title></head>\n";
	print qq'<body><img src="/graphics/jaegerfesting.gif">\n';

        print "<h2>Changelogs</h2>\n";
        foreach my $changelog (@changelogs) {
                print "<a href=\"avgo.pl?changelog=", $changelog->id(), "\">", $changelog->title(), "</a>\n";
		my $ccount = @{$changelog->comments()};
		if($ccount == 1) {
			print " ($ccount comment)";
		} elsif($ccount) {
			print " ($ccount comments)";
		}
		print "<br>\n";
        }
=for later
        if(@chatter) {
                print "<hr>\n";
                print "<h2>Chatter</h2>\n";
                foreach my $chat (@chatter) {
                        print "<b>$chat->{who}</b>: $chat->{line}<br>\n";
                }
        }
=cut
}

my $year = 1900 + (localtime)[5];

print "<hr><i>\&copy; 1999-$year Theodore Logan. All rights reserved.</i>\n";
print "</body></html>\n";
