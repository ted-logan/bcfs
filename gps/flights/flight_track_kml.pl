#!/usr/bin/perl

use strict;

print <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.1">
  <Document>
    <name>This is a flight</name>
    <Style id="track">
      <LineStyle>
        <color>c00000ff</color>
        <width>4</width>
      </LineStyle>
      <PolyStyle>
        <color>c00000ff</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>Flight</name>
      <styleUrl>#track</styleUrl>
      <LineString>
        <extrude>0</extrude>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>
XML


while(<>) {
	chomp;
	my @data = split;
	my $lat = $data[1];
	my $lon = $data[2];
	my $alt = $data[4] * 0.4048;
	if($lat != 0 || $lon != 0) {
		print "          $lon,$lat,$alt\n";
	}
}

print <<XML;
        </coordinates>
      </LineString>
    </Placemark>
  </Document>
</kml>
XML
