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

# This table is a view created from changelog that groups by year.
sub table {
	return 'changelog_year';
}

# provides a list of changelogs by year
sub new {
	my $package = shift;
	my $self;

	if(ref @_[0] eq 'HASH') {
		# Object was selected from the database.
		$self = $package->SUPER::new(@_);
	} else {
		my $year = shift;
		if($year) {
			# Create the object based on the year passed in. Verify
			# that the year is actually valid.
			$self = $package->SUPER::new();
			$self->{year} = $year;

			my $next_year = $year + 1;
			my $where = "time_begin >= '$year-01-01' and " .
				"time_begin < '$next_year-01-01' and " .
				$self->statusquery();

			unless(Count Jaeger::Changelog($where)) {
				return undef;
			}
		} else {
			# Select the most recent year
			$self = $package->SUPER::new();
			return $package->Select($self->statusquery() .
				" order by year desc");
		}

	}

	$self->{title} = "Browse $self->{year}";

	return $self;
}

sub statusquery {
	my $self = shift;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	return $self->{statusquery} = "status <= $level";
}

sub changelogs_by_year {
	my $self = shift;

	my $year = shift;
	my $next_year = $year + 1;

	return Jaeger::Changelog->Select(
		"time_begin>='$year-01-01' and time_begin<'$next_year-01-01' ".
		"and " . $self->statusquery() .
		' order by time_begin asc'
	);
}

# returns an object for the previous year, if any
sub _prev {
	my $self = shift;

	return Jaeger::Changelog::Browse->new($self->{year} - 1);
}

# returns an object for the next year, if any
sub _next {
	my $self = shift;

	return Jaeger::Changelog::Browse->new($self->{year} + 1);
}

# returns a link to the url of this year
sub _url {
	my $self = shift;
	return $self->{url} = $Jaeger::Base::BaseURL .
		"changelog/$self->{year}/";
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
		push @list, $lf->browse_changelog($changelog);
	}

	return $lf->changelog(
		title => $self->title(),
		content => join('', @list),
		navigation => $self->navigation(),
	);
}

sub all_years {
	my $self = shift;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}
	my $where = "status <= $level order by year";

	my @years;
	foreach my $year (Jaeger::Changelog::Browse->Select($where)) {
		if($year->{year} == $self->{year}) {
			push @years, "<b>$year->{year}</b>";
		} else {
			push @years, "<a href=\"" . $year->url() .
				"\">$year->{year}</a>";
		}
	}

	return @years;
}

sub navigation {
	my $self = shift;

	return "<center>" . join(' | ', $self->all_years()) . "</center>";
}

# Return a mini navigation bar, to be shown on the right side of the screen
sub mininav {
	my $self = shift;

	return join(' • ', $self->all_years());
}

1;
