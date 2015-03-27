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

sub _url {
	my $self = shift;

	return $self->{url} = "/changelog/series/" . $self->{id};
}

sub _title {
	my $self = shift;

	return $self->{title} = $self->{name};
}

sub _link {
	my $self = shift;

	return $self->{link} = '<a href="' . $self->url() . '">' .
		$self->title() . '</a>';
}

sub _html {
	my $self = shift;

	my $lf = $self->lf();

	my @list;

	my @changelogs = $self->changelogs();
	foreach my $changelog (@changelogs) {
		push @list, $lf->browse_changelog($changelog);
	}

	return $lf->changelog_tag_browse(
		title => $self->title(),
		content => join('', @list),
	);
}

sub add_changelog {
	my $self = shift;
	my $changelog = shift;
	my $position = shift;

	my $dbh = $self->Pgdbh();

	if(length($position)) {
		# Insert the changelog at a specific point. We may need to
		# adjust the position of existing entries.
		my $sql = "select * from changelog_series_entry " .
			"where series_id = $self->{id}";
		my $data = $dbh->selectall_hashref($sql, 'sort_order')
			or warn "$sql;\n";

		# Determine if an existing changelog has the same sort order as
		# the new changelog
		if($data->{$position}) {
			# Increment the sort order of every changelog >= the
			# requested sort order, starting at the end
			my $sql = "update changelog_series_entry " .
				"set sort_order = ? " .
				"where id = ?";
			my $sth = $dbh->prepare($sql)
				or warn "$sql;\n";

			foreach my $sort_order (
					sort {$b <=> $a}
					grep { $_ >= $position }
					keys $data) {
				$sth->execute($sort_order + 1, $data->{$sort_order}->{id})
					or warn "$sql $sort_order, $data->{$sort_order}->{id}\n";

			}
		}

	} else {
		# Position is empty; append to the end of the series.
		my $sql = "select max(sort_order) from changelog_series_entry ".
			"where series_id = $self->{id}";
		my @row = $dbh->selectrow_array($sql)
			or warn "$sql;\n";
		$position = $row[0] + 1;
	}

	my $sql = "insert into changelog_series_entry " .
		"(series_id, sort_order, changelog_id) values " .
		"($self->{id}, $position, $changelog->{id})";
	$dbh->do($sql)
		or warn "Unable to update changelog series: $sql;\n";

	return 1;
}

sub delete_changelog {
	my $self = shift;
	my $changelog = shift;

	my $sql = "delete from changelog_series_entry " .
		"where series_id = $self->{id} " .
		"and changelog_id = $changelog->{id}";

	my $dbh = $self->Pgdbh();
	$dbh->do($sql)
		or warn "Unable to update changelog series: $sql;\n";

	return 1;
}

1;
