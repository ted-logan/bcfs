#!/usr/bin/perl

# $Id: avgo.pl,v 1.1 2002-11-02 17:06:29 jaeger Exp $

# Plain-text output of jaegerfesting for avantgo chanel
# 09 September 2000

use lib '/home/jaeger/programming/webpage/lib';

use strict;

use Jaeger::Changelog;
use CGI;

print "content-type: text/html\n\n";

my $q = new CGI;

if(my $id = $q->param('changelog')) {
        my $changelog = new Jaeger::Changelog($id);

        print "<html><head><title>", $changelog->title(), "</title></head>\n";
        print "<h2>", $changelog->title(), "</h2>\n";
	print "<h3>", $changelog->time_begin(), "</h3>\n";
        my $content = $changelog->content();
        # to simplify things, strip the <a ...> tags
        $content =~ s/<\/?a.*?>//g;
        print "$content\n";
        print "<hr>\n";

        if(my $prev = $changelog->prev()) {
                print "&lt;- <a href=\"avgo.pl?changelog=", $prev->id(), "\">", $prev->title(), "</a> | ";
        }
        print "<a href=\"avgo.pl\">jaegerfesting</a>";
        if(my $next = $changelog->next()) {
                print " | <a href=\"avgo.pl?changelog=", $next->id(), "\">", $next->title(), "</a> -&gt;\n";
        }
} else {
        my @changelogs = All Jaeger::Changelog(undef, 'time_begin desc', 10);
=for later	
        my $chatterbox = new Shared::Chatter;
        my @chatter = $chatterbox->recent("timestamp > now() + '-2d'", 10);
=cut

        print "<html><head><title>jaegerfesting: Mobile</title></head>\n";
	print qq'<body><img src="/graphics/jaegerfesting.gif">\n';

        print "<h2>Changelogs</h2>\n";
        foreach my $changelog (@changelogs) {
                print "<a href=\"avgo.pl?changelog=", $changelog->id(), "\">", $changelog->title(), "</a><br>\n";
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

print "<hr><i>\&copy; 1999-2002 Ted Logan. All rights reserved.</i>\n";
print "</body></html>\n";
