package Jaeger::Calvin;

# Show photos for one of our children, matching a specific substring

use strict;

use Carp;
use Jaeger::Base;
use Jaeger::Photo;

sub new {
	my $package = shift;

	my $name = shift;

	croak "Must specify substring match (name)" unless $name;

	my $self = bless {}, $package;
	$self->{name} = $name;

	return $self;
}

sub html {
	my $self = shift;

	my $name = $self->{name};
	my $ucname = ucfirst $name;

	my $dbh = Jaeger::Base::Pgdbh();

	my @months = do {
		my @months;

		my $sql = 
			"select month from ${name}_photo_month group by month";
		my $sth = $dbh->prepare($sql);
		$sth->execute() or warn "$sql;\n";
		while(my ($month) = $sth->fetchrow_array()) {
			push @months, $month;
		}

		sort @months;
	};

	# Show only a month's worth of photos at a time. The "everything from
	# the past three years" worked better when the entire back catalog of
	# Calvin's photos only dated several months.
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
<head><title>$ucname Logan</title>
<link rel="stylesheet" type="text/css" href="/tlogan.css" />
<link href="/${name}_rss.cgi" rel="alternate" type="application/rss+xml" title="rss" />
HTML
	if($self->{tagline}) {
		my $tagline = $self->{tagline};
		print <<HTML;
<meta name="description" content="$tagline" />
HTML
	}
	print <<HTML;
</head>
<body>

<div id="body">
<div style="float: right; padding-top: 10px; padding-right: 10px;"><a href="/${name}_rss.cgi">RSS</a></div>
<h1><a href="/">$ucname Logan</a></h1>

HTML

	if($self->{tagline}) {
		my $tagline = $self->{tagline};
		print <<HTML;
<p>
$tagline
</p>

HTML
	}

	my $where = "id in " .
		"(select id from ${name}_photo_month where month = '$month') ".
		"order by date desc";
	my @photos = Jaeger::Photo->Select($where);

	foreach my $photo (@photos) {
		$photo->{size} = '640x480';
		$photo->resize();

		my $date = $photo->date_format();

		# Reformat names from our children's perspective
		$photo->{description} =~ s/Kiesa/Mommy/;
		$photo->{description} =~ s/Jaeger/Daddy/;

		print <<HTML;
<a name="$photo->{round}/$photo->{number}"></a>
<h3><a href="/?month=$month#$photo->{round}/$photo->{number}">$photo->{description}</a></h3>
<p><i>$date</i></p>
<p><img src="http://jaeger.festing.org/digitalpics/$photo->{round}/$photo->{size}/$photo->{number}.jpg" /></p>
HTML
	}

	if($month eq $months[0] && $self->{intro}) {
		print $self->{intro};
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

	return 1;
}

1;
