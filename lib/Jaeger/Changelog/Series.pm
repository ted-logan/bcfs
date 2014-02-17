package		Jaeger::Changelog::Series;

# Package to allow browsing by series of changelogs

# 28 March 2010
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Changelog;
use Jaeger::Lookfeel;
use Jaeger::User;

@Jaeger::Changelog::Series::ISA = qw(Jaeger::Base);

sub table {
	return 'changelog_series';
}

# Given a changelog object, return a list of the the series objects that
# include the changelog, which may be empty
sub new_by_changelog {
	my $package = shift;

	my $changelog = shift;

	my $subquery =
		"select series_id from changelog_series_entry " .
		"where changelog_id = " . $changelog->id();

	return $package->Select("id in ($subquery)");
}

sub changelogs {
	my $self = shift;

	my $level;
	if(my $user = Jaeger::User->Login()) {
		$level = $user->{status};
	} else {
		$level = 0;
	}

	# Select all of the changelogs from the series (visible by the current
	# user), sorting by the sort_order
	return Jaeger::Changelog->Select(
		"join changelog_series_entry " .
		"on changelog.id = changelog_series_entry.changelog_id " .
		"where series_id = $self->{id} " .
		"and status <= $level " .
		"order by sort_order"
	);
}

1;
