package Jaeger::Mapper;

#
# $Id:
#

# Helper package to select from a _map table

# Created  27 November 2003

use strict;

use Jaeger::Base;

@Jaeger::Mapper::ISA = qw(Jaeger::Base);

# Parameters:
#    table  _map table to select data from
#    field  
#    id     
sub Map {
	my $package = shift;

	my %params = @_;

	my $map = {};

	my $sql = "select * from $params{table} where $params{idfield} = $params{id}";
	my $sth = $Jaeger::Base::Pgdbh->prepare($sql);
	$sth->execute() or warn "$sql;\n";

	my $field = $params{field};
	$field =~ s/_id//;

	while(my $row = $sth->fetchrow_hashref()) {
		my $id = $row->{$params{field}};
		$map->{$id} = {
			%$row,
			$field => $params{package}->new_id($id),
		};
	}

	return $map;
}
