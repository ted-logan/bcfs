package Jaeger::Photo::Set;

# Jaeger::Photo::Set: Photo set object

use strict;

use Jaeger::Base;
use Jaeger::Photo;
use Jaeger::Photo::List;

@Jaeger::Photo::Set::ISA = qw(Jaeger::Photo::List);

# Select all sets with beginning and ending dates set. For those sets, check
# for new photos inside the date range, and add them to the sets.
sub AutoUpdateSets {
	my $package = shift;

	my @sets = $package->Select(
		"date_begin is not null and date_end is not null"
	);

	foreach my $set (@sets) {
		$set->auto_update_set();
	}
}

sub table {
	return 'photo_set';
}

sub _directory {
	my $self = shift;

	my $name = lc $self->{name};
	$name =~ s/'//g;
	$name =~ s/[^a-z0-9]+/_/g;
	$name =~ s/^_//;
	$name =~ s/_$//;

	return $self->{directory} =
		'/home/jaeger/graphics/photos/sets/' . $name;
}

sub _statusquery {
	my $self = shift;

	my $status = 0;
	if(my $user = Jaeger::User->Login()) {
		$status = $user->{status};
	}

	return $self->{statusquery} = "status <= $status and not hidden";
}

sub _photos {
	my $self = shift;
	my $id = $self->id();
	$self->{photos} = [Jaeger::Photo->Select("join photo_set_map on photo.id = photo_set_map.photo_id where photo_set_map.photo_set_id = $id and " . $self->statusquery() . " order by date")];
	return $self->{photos};
}

sub add {
	my $self = shift;
	foreach my $photo (@_) {
		my $sql = "insert into photo_set_map values (" .
			$self->id() . ", " .
			$photo->id() . ")";
		$self->dbh()->do($sql)
			or warn "$sql;\n";
	}
}

sub _title {
	my $self = shift;

	return $self->{title} = "Photo set: " . $self->{name};
}

sub _url {
	my $self = shift;

	return $self->{url} = $Jaeger::Base::BaseURL .
		"photo.cgi?set=$self->{id}";
}

# If this set has a beginning and ending date specified, look for new pictures
# within that date range, and add those pictures to the set.
sub auto_update_set {
	my $self = shift;

	return unless $self->{date_begin};
	return unless $self->{date_end};

	# Use the photo_date view, which takes into account the time zone
	# offset; so we interpret the start and end dates for each photo set in
	# the photo's native time zone.
	my $sql = "insert into photo_set_map " .
		"select $self->{id}, id from photo_date " .
		"where date >= extract(epoch from timestamp '$self->{date_begin}') " .
		"and date <= extract(epoch from timestamp '$self->{date_end}') " .
		"and id not in (select photo_id from photo_set_map where photo_set_id = $self->{id})";

	warn "About to update photo set $self->{id}: $self->{date_begin} -- $self->{date_end}\n";

	$self->Pgdbh()->do($sql)
		or warn $sql;
}

1;
