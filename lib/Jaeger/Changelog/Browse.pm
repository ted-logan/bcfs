package		Jaeger::Changelog::Browse;

#
# $Id: Browse.pm,v 1.6 2008-06-28 19:08:23 jaeger Exp $
#

# package to allow browsing by years of changelogs

# 01 September 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::User;

@Jaeger::Changelog::Browse::ISA = qw(Jaeger::Base);

@Jaeger::Changelog::Browse::Params = qw(id title time_begin time_end content);

# provides a list of changelogs by year
sub new {
	my $package = shift;

	my $year = shift;
	unless($year) {
		$year = (localtime)[5] + 1900;
	}

	my $next_year = $year + 1;
	my $where = "time_begin >= '$year-01-01' and " .
		"time_begin < '$next_year-01-01'";

	unless(Count Jaeger::Changelog($where)) {
		return undef;
	}

	my $self = $package->SUPER::new();

	$self->{title} = "Browse $year";
	$self->{year} = $year;

	return $self;
}

sub changelogs_by_year {
	my $self = shift;

	my $year = shift;
	my $next_year = $year + 1;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	return Jaeger::Changelog->Select(
		"status <= $level and " .
		"time_begin>='$year-01-01' and time_begin<'$next_year-01-01' ".
		'order by time_begin asc'
	);
}

# returns an object for the previous year, if any
sub _prev {
	my $self = shift;

	return Jaeger::Changelog->Browse($self->{year} - 1);
}

# returns an object for the next year, if any
sub _next {
	my $self = shift;

	return Jaeger::Changelog->Browse($self->{year} + 1);
}

# returns a link to the url of this year
sub _url {
	my $self = shift;
	return $self->{url} = "$Jaeger::Base::BaseURL/changelog/$self->{year}/";
}

# returns html for this object
sub _html {
	my $self = shift;

	my $lf = $self->lf();

	my $year = $self->{year};

	my @changelogs = $self->changelogs_by_year($year);

	my @list;
	my $last_month;
	foreach my $changelog (@changelogs) {
		my ($year, $month) = split /-/, $changelog->time_begin();
		if($month ne $last_month) {
			push @list, $lf->browse_newmonth(
				month => "$Jaeger::Base::Months[$month] $year"
			);
			$last_month = $month;
		}
		push @list, $lf->browse_changelog(
			url => $changelog->url(),
			title => $changelog->title(),
			time_begin => $changelog->time_begin(),
			visibility => $Jaeger::Changelog::Status{$changelog->status()},
			summary => $changelog->summary(),
			tags => $changelog->tags(),
		);
	}

	return $lf->changelog(
		title => $self->title(),
		content => join('', @list),
		navigation => $self->navigation(),
	);
}

sub navigation {
	my $self = shift;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	my $sql = "select extract(year from time_begin) from changelog " .
		"where status <= $level " .
		"group by date_part order by date_part";

	my $sth = $self->dbh()->prepare($sql);
	$sth->execute()
		or warn "$sql;\n";

	my @years;
	while(my @row = $sth->fetchrow_array()) {
		if($row[0] == $self->{year}) {
			push @years, "<b>$row[0]</b>";
		} else {
			push @years, "<a href=\"$Jaeger::Base::BaseURL/changelog/$row[0]/\">$row[0]</a>";
		}
	}

	return "<center>" . join(' | ', @years) . "</center>";
}

1;
