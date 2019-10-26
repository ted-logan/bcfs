package		Jaeger::Changelog::Tag;

# package to allow browsing changelog tags

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::User;

@Jaeger::Changelog::Tag::ISA = qw(Jaeger::Base);

@Jaeger::Changelog::Tag::Sizes = qw(smaller small medium large larger x-large xx-large);

sub table {
	return 'changelog_tag_view';
}

# provides a list of changelogs by tag, or a list of changelog tags
sub new {
	my $package = shift;
	my $self;

	if(ref $_[0] eq 'HASH') {
		$self = $package->SUPER::new(@_);
	} else {
		my $tag = shift;

		$self = $package->SUPER::new();

		if($tag) {
			$self->{tag} = $tag;

			# If no visible changelogs exist for this tag, return
			# undef, which the Uri mapper will interpret as a 404.
			my $changelog_by_tag =
				$self->changelogs_by_tag($self->{tag});
			unless(@$changelog_by_tag) {
				return undef;
			}
		}
	}

	return $self;
}

# Returns the status level of the currently-logged-in-user, or 0 if no user is
# logged in
sub _level {
	my $self = shift;

	if(my $user = Jaeger::User->Login()) {
		return $self->{level} = $user->{status};
	} else {
		return $self->{level} = 0;
	}
}

sub _all_tags {
	my $self = shift;

	my $level = $self->level();

	# TODO consider replacing this with the changelog_tag_view view
	my $sql = "select tag.name, count(*) from tag " .
	    "join changelog_tag_map on tag.id = changelog_tag_map.tag_id " .
	    "join changelog on changelog.id = changelog_tag_map.changelog_id " .
	    "where status <= $level group by tag.name";

	my $tags = Jaeger::Base::Pgdbh()->selectall_arrayref($sql);

	unless($tags) {
		warn "Select tags: $sql;\n";
		return [];
	}

	return $self->{all_tags} = { map {$_->[0], $_->[1]} @$tags };
}

sub _changelogs_by_tag {
	my $self = shift;

	my $tag = shift;

	my $level = $self->level();

	return $self->{changelog_by_tag} = [Jaeger::Changelog->Select(
		"join changelog_tag_map " .
		"on changelog.id = changelog_tag_map.changelog_id " .
		"join tag on tag.id = changelog_tag_map.tag_id " .
		"where status <= $level and " .
		"tag.name = '$tag' " .
		"order by time_begin desc"
	)];
}

sub _title {
	my $self = shift;

	if($self->{tag}) {
		return $self->{title} = "Browse tag $self->{tag}";
	} else {
		return $self->{title} = "Browse tags";
	}
}

sub _url {
	my $self = shift;

	$self->{url} = $Jaeger::Base::BaseURL . "changelog/tag/$self->{tag}";

	return $self->{url};
}

sub _index {
	my $self = shift;

	if($self->{tag}) {
		# Browse up to the list of all tags
		return $self->{index} = new Jaeger::Changelog::Tag();
	} else {
		return $self->{index} = undef;
	}
}

sub tag_cloud {
	my $self = shift;

	my @list;

	my $tags = $self->all_tags();
	my $logtags = { map { $_, log $tags->{$_} } keys %$tags };

	my $min = undef;
	my $max = undef;
	foreach my $count (values %$logtags) {
		if(!defined($min) || $count < $min) {
			$min = $count;
		}
		if(!defined($max) || $count > $max) {
			$max = $count;
		}
	}

	foreach my $tag (sort keys %$logtags) {
		my $size = ($logtags->{$tag} - $min) / ($max - $min);
		my $i = $size * (@Jaeger::Changelog::Tag::Sizes - 1);
		my $s = $Jaeger::Changelog::Tag::Sizes[$i];
		push @list, "<span style=\"font-size: $s\">" .
			"<a href=\"/changelog/tag/$tag\">$tag</a>" .
			"</span>\n"
	}

	return join('', @list);
}

# returns html for this object
sub _html {
	my $self = shift;

	my $lf = $self->lf();

	if($self->{tag}) {
		my @list;

		my $changelogs = $self->changelogs_by_tag($self->{tag});
		foreach my $changelog (@$changelogs) {
			push @list, $lf->browse_changelog($changelog);
		}

		return $lf->changelog_tag_browse(
			title => $self->title(),
			content => join('', @list),
		);
	} else {
		return $lf->changelog_tag_cloud(
			title => $self->title(),
			content => $self->tag_cloud(),
		);
	}
}

# Return a mini navigation bar/tag cloud, to be shown on the right side of the
# screen
sub mininav {
	my $self = shift;

	return $self->tag_cloud();
}

1;
