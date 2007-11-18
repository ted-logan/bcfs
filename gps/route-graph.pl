#!/usr/bin/perl

# Generate KML to show the waypoints we care about, a ten-meter circle
# around each waypoint, and lines between each pair.

use strict;

use lib '/home/jaeger/src/bcfs-local/lib';

use waypoints;

# load the waypoints
my %waypoints = waypoints::load_waypoints("waypoints-2007-11-11.gpx");

# Pare down the waypoints according to the list of pairs we're interested in
my %waypoints_of_interest;
foreach my $pair (@waypoints::pairs) {
	foreach my $wpt (@$pair) {
		if(exists $waypoints{$wpt}) {
			$waypoints_of_interest{$wpt} = $waypoints{$wpt};
		} else {
			warn "Waypoint '$wpt' not found!\n";
		}
	}
}

open KML, ">route-graph.kml"
	or die "Can't write kml: $!\n";

print KML <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.1">
  <Document>
    <name>Routes: Waypoint graph</name>
    <description>Shows the waypoints we care about, a ten-meter circle around each waypoint, and lines connecting the waypoint pairs.</description>
    <Style id="route_edge">
      <LineStyle>
        <color>a040c0cc</color>
        <width>2</width>
      </LineStyle>
      <PolyStyle>
        <color>a040c0cc</color>
      </PolyStyle>
    </Style>
    <Style id="junction">
      <IconStyle>
        <color>ff0055ff</color>
	<scale>0.40</scale>
        <Icon>
	  <href>http://kh.google.com:80/flatfile?lf-0-icons/773_n.png</href>
        </Icon>
      </IconStyle>
      <LineStyle>
        <color>40c00000</color>
        <width>1</width>
      </LineStyle>
    </Style>
    <Folder>
      <name>Junctions</name>
      <visibility>1</visibility>
      <open>0</open>
XML

foreach my $waypoint (sort keys %waypoints_of_interest) {
	my $point = $waypoints_of_interest{$waypoint};
	print KML <<XML
      <Placemark>
        <name>$waypoint</name>
        <styleUrl>#junction</styleUrl>
	<Point>
	  <coordinates>$point->{longitude},$point->{latitude}</coordinates>
	</Point>
      </Placemark>
XML
}

print KML <<XML;
    </Folder>
    <Folder>
      <name>Edges</name>
      <visibility>1</visibility>
      <open>0</open>
XML

foreach my $pair (@waypoints::pairs) {
	my $wp0 = $waypoints_of_interest{$pair->[0]};
	my $wp1 = $waypoints_of_interest{$pair->[1]};
	next unless $wp0 && $wp1;

	print KML <<XML
      <Placemark>
	<name>$pair->[0] &lt;-&gt; $pair->[1]</name>
	<styleUrl>#route_edge</styleUrl>
	<LineString>
          <extrude>0</extrude>
	  <tessellate>1</tessellate>
	  <altitudeMode>clampToGround</altitudeMode>
	  <coordinates>
	    $wp0->{longitude},$wp0->{latitude}
	    $wp1->{longitude},$wp1->{latitude}
	  </coordinates>
        </LineString>
      </Placemark>
XML
}

print KML <<XML;
    </Folder>
  </Document>
</kml>
XML

close KML;
