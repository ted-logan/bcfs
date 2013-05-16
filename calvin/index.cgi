#!/usr/bin/perl

# calvin/index.cgi: Shows photos matching the text "Calvin"

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Photo;

my $dbh = Jaeger::Base::Pgdbh();

my @months = do {
	my @months;

	my $sql = "select month from calvin_photo_month group by month";
	my $sth = $dbh->prepare($sql);
	$sth->execute() or warn "$sql;\n";
	while(my ($month) = $sth->fetchrow_array()) {
		push @months, $month;
	}

	sort @months;
};

# Show only a month's worth of photos at a time. The "everything from the past
# three years" worked better when the entire back catalog of Calvin's photos
# only dated several months.
my $month = do {
	my $query = Jaeger::Base->Query();
	if($query->param('month')) {
		$query->param('month');
	} else {
		$months[-1];
	}
};

print "content-type: text/html; charset=UTF-8\n\n";

print <<HTML;
<html>
<head><title>Calvin Logan</title>
<link rel="stylesheet" type="text/css" href="/tlogan.css" />
<link href="/calvin_rss.cgi" rel="alternate" type="application/rss+xml" title="rss" />
<meta name="description" content="The continuing adventures of an intrepid preschooler" />
</head>
<body>

<div id="body">
<div style="float: right; padding-top: 10px; padding-right: 10px;"><a href="/calvin_rss.cgi">RSS</a></div>
<h1><a href="/">Calvin Logan</a></h1>

<p>
The continuing adventures of an intrepid preschooler
</p>

HTML

my $where = "id in (select id from calvin_photo_month where month = '$month') ".
	"order by date desc";
my @photos = Jaeger::Photo->Select($where);

foreach my $photo (@photos) {
	$photo->{size} = '640x480';
	$photo->resize();

	my $date = $photo->date_format();

	# Reformat names from Calvin's perspective
	$photo->{description} =~ s/Kiesa/Mommy/;
	$photo->{description} =~ s/Jaeger/Daddy/;

	print <<HTML;
<a name="$photo->{round}/$photo->{number}"></a>
<h3><a href="/?month=$month#$photo->{round}/$photo->{number}">$photo->{description}</a></h3>
<p><i>$date</i></p>
<p><img src="http://jaeger.festing.org/digitalpics/$photo->{round}/$photo->{size}/$photo->{number}.jpg" /></p>
HTML
}

if($month eq $months[0]) {
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
HTML
}

# Show links to all the months for which photos are available
print "<p>\n";
my $last_year;
foreach my $month (@months) {
	my ($y, $m) = $month =~ /^(\d\d\d\d)-(\d\d)/;
	if($last_year ne $y) {
		print "$y: ";
		$last_year = $y;
	} elsif(defined $last_year) {
		print "| ";
	}
	print qq'<a href="/?month=$month">$Jaeger::Base::Months[$m]</a> ';
}
print "</p>\n";

print <<HTML;
</div>
</body></html>
HTML
