package	waypoints;

use strict;

use Jaeger::GPS;
use XML::DOM;

# In the future, we should load the waypoint pairs we're interested in
# from a database or from a file.

@waypoints::pairs = (
	['CHAUTAUQUA', 'MESA JCT 1'],
	['MESA JCT 1', 'MESA JCT 2'],
	['MESA JCT 2', 'MESA JCT 3'],
	['MESA JCT 3', 'MESA JCT 4'],
	['MESA JCT 4', 'MESA JCT 5'],
	['MESA JCT 5', 'MESA JCT 6'],
	['MESA JCT 6', 'MESA JCT 7'],
	['MESA JCT 7', 'MESA JCT 8'],
	['MESA JCT 8', 'MESA JCT 9'],
	['MESA JCT 9', 'MSA FRN J1'],
	['MSA FRN J1', 'MSA FRN JC'],
	['MSA BLU JC', 'MSA SHN JC'],
	['MSA BLU JC', 'MSA JCT 10'],
	['MSA JCT 10', 'MSA SHD JC'],
	['MSA SHN JC', 'MSA FRN JC'],
	['MSA FRN JC', 'FERN JCT'],
	['SOUTH MESA', 'MSA HM JCT'],
	['MSA FRN JC', 'N SHN JCT'],
	['MSA FRN J1', 'FERN JCT'],
	['FERN JCT', 'BEAR SADLE'],
	['BEAR SADLE', 'BEAR J1'],
	['BEAR J1', 'BEAR PEAK'],
	['BEAR J1', 'BEAR J2'],
	['BEAR J2', 'STH BR JCT'],
	['GRN BR JCT', 'GREEN JCT'],
	['GRN BR JCT', 'BEAR J2'],
	['STH BR JCT', 'S BDR PEAK'],
	['STH BR JCT', 'MSA SHD JC'],
	['MESA JCT 9', 'GRN BR JCT'],
	['GREGORY', 'GRG SAD JC'],
	['GRG SAD JC', 'SADDLE RK'],
	['GRG SAD JC', 'GRG CR JCT'],
	['GRG CR JCT', 'RNG GRG JC'],
	['FLAGSTAFF', 'RNG GRG JC'],
	['RNG GRG JC', 'RNG LNG JC'],
	['RNG LNG JC', 'GRN RNG JC'],
	['GRN RNG JC', 'OLD GNM JC'],
	['OLD GNM JC', 'SAD GRN JC'],
	['GRN RNG JC', 'GREEN JCT'],
	['GREEN JCT', 'GREEN MTN'],
	['GREGORY', 'GREG JCT'],
	['GREG JCT', 'SADDLE RK'],
	['SADDLE RK', 'SADDLE J2'],
	['SADDLE J2', 'SAD GRN JC'],
	['SAD GRN JC', 'OLD GNM J2'],
	['OLD GNM J2', 'GREEN MTN'],
	['NCAR', 'NCAR JCT'],
	['NCAR JCT', 'MESA JCT 6'],
	['NCAR JCT', 'MESA JCT 7'],
	['MESA JCT 1', 'CH J15'],
	['CH J15', 'CH J9'],
	['CH J9', 'CH J14'],
	['CH J14', 'ROYAL ARCH'],
	['MESA JCT 3', 'WOODS QRY'],
	['CHAUTAUQUA', 'CH J1'],
	['CH J1', 'CH J2'],
	['CH J2', 'CH J3'],
	['CH J3', 'CH J4'],
	['CH J4', 'CH J5'],
	['CH J5', 'GREG JCT'],
	['CH J5', 'CHAUTAUQUA'],
	['CH J4', 'CH J1'],
	['CH J2', 'CH J6'],
	['CH J6', 'CH J7'],
	['CH J6', 'CH J10'],
	['CH J7', 'CH J8'],
	['CH J7', 'CH J15'],
	['CH J8', 'CH J9'],
	['CH J8', 'CH J10'],
	['CH J10', 'CH J3'],
	['CH J10', 'CH J12'],
	['CH J3', 'CH J12'],
	['CH J12', 'CH J13'],
	['CH J13', 'CH J14'],
);

sub load_waypoints {
	my $file = shift;

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile($file);

	my %waypoints;

	my $nodes = $doc->getElementsByTagName("wpt");
	for(my $i = 0; $i < $nodes->getLength(); $i++) {
		my $node = $nodes->item($i);

		my $waypoint = new Jaeger::GPS;
		$waypoint->{latitude} =
			$node->getAttributeNode("lat")->getValue();
		$waypoint->{longitude} =
			$node->getAttributeNode("lon")->getValue();
		if(my @n = $node->getElementsByTagName('ele')) {
			$waypoint->{elevation} =
				$n[0]->getFirstChild()->getData();
		}
		if(my @n = $node->getElementsByTagName('name')) {
			my $name = $n[0]->getFirstChild()->getData();
			$waypoints{$name} = $waypoint;
		}
	}

	$doc->dispose();

	return %waypoints;
}

1;
