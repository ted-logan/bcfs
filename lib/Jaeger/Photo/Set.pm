package Jaeger::Photo::Set;

# Jaeger::Photo::Set: Photo set object

use strict;

use Jaeger::Base;
use Jaeger::Photo;
use Jaeger::Photo::List;

@Jaeger::Photo::Set::ISA = qw(Jaeger::Photo::List);

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

	return $self->{url} = "/photo.cgi?set=$self->{id}";
}

1;
