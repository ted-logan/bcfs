#!/usr/bin/perl

# Estimate the miles driven per year, based on the data available.

use strict;

die "\$BCFS must be set!\n" unless $ENV{BCFS};

use lib "$ENV{BCFS}/lib";

use Jaeger::Base;
use Jaeger::Vehicle;

open HTML, ">mileage.html"
	or die "Can't open mileage.html: $!\n";

my $sql = "select extract(year from date) as \"year\", date, mileage " .
	"from mileage where vehicle_id = ? order by mileage";
my $sth = Jaeger::Base::Pgdbh()->prepare($sql);
my @vehicles = Jaeger::Vehicle->Select("1=1 order by id");
foreach my $vehicle (@vehicles) {
	print "Vehicle: ", $vehicle->name(), "\n";
	print "Year\tEOY\tMiles/Year\n";
	print "----\t------\t----------\n";

	print HTML "<h2>", $vehicle->name(), "</h2>\n";
	print HTML <<HTML;
<table border="1">
<tr><th>Year</th> <th>End-of-year mileage</th> <th>Miles/Year</th></tr>
HTML

	$sth->execute($vehicle->id())
		or die "$sql;\n";
	my %last = ();
	while(my $row = $sth->fetchrow_hashref()) {
		if($row->{year} != $last{year}) {
			extrapolate($vehicle, \%last, $row);
		}
		%last = %$row;
	}
	extrapolate($vehicle, \%last, undef);

	print "\n";

	print HTML "</table>\n";
}

print "Mileage summary\n";
print "Year\tFlights\t", join("\t", map {$_->name()} @vehicles), "\n";

print HTML <<HTML;
<h2>Mileage summary</h2>
<table border="1">
HTML

print HTML "<th>Year</th> <th>Flights</th>",
	join(" ", map {"<th>" . $_->name() . "</th>"} @vehicles), "</tr>\n";

$sql = "select * from flights_by_year";
$sth = Jaeger::Base::Pgdbh()->prepare($sql);
$sth->execute()
	or die "$sql;\n";
while(my $row = $sth->fetchrow_hashref()) {
	my @row;
	push @row, $row->{year};
	push @row, $row->{miles};
	foreach my $vehicle (@vehicles) {
		push @row, $vehicle->{mpy}->{$row->{year}};
	}
	print join("\t", @row), "\n";
	print HTML "<tr>",
		join(" ", map {"<td align=\"right\">" . $_ . "</td>"} @row),
		"</tr>\n";
}

print HTML "</table>\n";

close HTML;

sub extrapolate {
	my $vehicle = shift;
	my $last = shift;
	my $first = shift;

	if(%$last && !$first) {
		my $mpy = $last->{mileage} - $vehicle->{year}->{$last->{year}};
		$vehicle->{mpy}->{$last->{year}} = $mpy;
		printf "%s\t%6d\t%5d\n",
			$last->{year}, $last->{mileage}, $mpy;
		printf HTML "<tr><td>%d</td> <td align=\"right\">%d</td> <td align=\"right\">%d</td></tr>\n",
			$last->{year}, $last->{mileage}, $mpy;
	}

	if(%$last && $first) {
		my $nyd = $first->{year} . "-01-01";
		my $x = datediff($nyd, $last->{date}) /
			datediff($first->{date}, $last->{date});
		my $mileage = int(($first->{mileage} - $last->{mileage}) * $x + $last->{mileage});
		my $mpy = $mileage - $vehicle->{year}->{$last->{year}};
		$vehicle->{mpy}->{$last->{year}} = $mpy;
		printf "%s\t%6d\t%5d\n",
			$last->{year}, $mileage, $mpy;
		printf HTML "<tr><td>%d</td> <td align=\"right\">%d</td> <td align=\"right\">%d</td></tr>\n",
			$last->{year}, $mileage, $mpy;
		$vehicle->{year}->{$first->{year}} = $mileage;
	}

	if($first && !%$last) {
#		printf "init\t%6d\n", $first->{mileage};
		$vehicle->{year}->{$first->{year}} = $first->{mileage};
	}
}

sub datediff {
	my $last = shift;
	my $first = shift;

	my $sql = "select date(?) - date(?)";
	my $sth = Jaeger::Base::Pgdbh->prepare($sql);
	$sth->execute($last, $first)
		or die "$sql;\n";
	return ($sth->fetchrow_array())[0];
}
