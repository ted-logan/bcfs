#!/usr/bin/perl

# calvin/index.cgi: Shows photos matching the text "Calvin"

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;

print "content-type: text/html; charset=UTF-8\n\n";

print <<HTML;
<html>
<head><title>Calvin Logan</title>
<link rel="stylesheet" type="text/css" href="/tlogan.css" />
<link href="/calvin_rss.cgi" rel="alternate" type="application/rss+xml" title="rss" />
</head>
<body>

<div id="body">
<div style="float: right; padding-top: 10px; padding-right: 10px;"><a href="/calvin_rss.cgi">RSS</a></div>
<h1>Calvin Logan</h1>

<p>
Calvin Theodore Stone Logan was born at 22:02 MDT on 26 March 2009. He
was 8 pounds, 15 ounces, and 21 inches long.
</p>
HTML

my $where = "description ilike '%calvin%' and not hidden order by date desc";
my @photos = Jaeger::Photo->Select($where);

foreach my $photo (@photos) {
	$photo->{size} = '640x480';
	$photo->resize();

	my $date = $photo->date_format();

	print <<HTML;
<a name="$photo->{round}/$photo->{number}"></a>
<h3>$photo->{description}</h3>
<p><i>$date</i></p>
<p><img src="http://jaeger.festing.org/digitalpics/$photo->{round}/$photo->{size}/$photo->{number}.jpg" /></p>
HTML
}

print <<HTML;
<h3>32 Weeks</h3>

<p>
<img src="calvin-32weeks.jpg" />
</p>

<p>
I think this is Calvin's head in profile; the diagonal white line in the
upper left of the picture is his nose.
</p>

<h3>20 Weeks</h3>

<p>
<img src="calvin_20.jpg" />
</p>

<h3>13 Weeks</h3>

<p>
<embed id="VideoPlayback" src="http://video.google.com/googleplayer.swf?docid=-7470424492462578025&hl=en&fs=true" style="width:400px;height:326px" allowFullScreen="true" allowScriptAccess="always" type="application/x-shockwave-flash"> </embed>
</p>

<h3>7 Weeks</h3>

<p>
<img src="http://jaeger.festing.org/changelog/2008-08-30/calvin_or_jade.jpg" alt="Calvin? Jade? You decide." />
</p>

</div>
</body></html>
HTML
