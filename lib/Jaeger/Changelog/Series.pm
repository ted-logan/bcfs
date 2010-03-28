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

	my $subquery =
		"select changelog_id from changelog_series_entry " .
		"where series_id = $self->{id} " .
		"order by sort_order";

	# I can't quite figure out how to get my database-object mapper to sort
	# by changelog_series_entry.sort_order, so I'm sorting by
	# changelog.time_begin until I tweak my database-object mapper to
	# support joins, which won't happen until I desperately need this
	# feature.
	return Jaeger::Changelog->Select(
		"status <= $level and " .
		"id in ($subquery) " .
		"order by time_begin"
	);
}

1;
