#!/usr/bin/perl

use strict;

open KML, ">flights.kml"
	or die "Can't write flights.kml: $!\n";

print KML <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.1">
  <Document>
    <name>Flights</name>
    <Style id="track">
      <LineStyle>
        <color>c00000ff</color>
        <width>4</width>
      </LineStyle>
      <PolyStyle>
        <color>c00000ff</color>
      </PolyStyle>
    </Style>
XML

foreach my $file (sort <*.txt>) {
	my $title = $file;
	$title =~ s/\.txt$//;
	$title =~ s/-([a-z]+)/ \U$1/i;

	print KML <<XML;
    <Placemark>
      <name>$title</name>
      <styleUrl>#track</styleUrl>
      <LineString>
        <extrude>0</extrude>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>
XML

	open TRACK, $file;
	while(<TRACK>) {
		chomp;
		my @data = split;
		my $lat = $data[1];
		my $lon = $data[2];
		my $alt = $data[4] * 0.4048;
		if($lat != 0 || $lon != 0) {
			print KML "          $lon,$lat,$alt\n";
		}
	}
	close TRACK;

	print KML <<XML;
        </coordinates>
      </LineString>
    </Placemark>
XML
}

print KML <<XML;
  </Document>
</kml>
XML
