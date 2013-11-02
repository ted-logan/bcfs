package Jaeger::Photo::Set;

# Jaeger::Photo::Set: Photo set object

use strict;

use Jaeger::Base;
use Jaeger::Photo;

@Jaeger::Photo::Set::ISA = qw(Jaeger::Base);

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

sub photos {
	my $self = shift;
	my $id = $self->id();
	return Jaeger::Photo->Select("join photo_set_map on photo.id = photo_set_map.photo_id where photo_set_map.photo_set_id = $id order by date");
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

1;
