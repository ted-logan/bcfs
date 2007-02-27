#!/usr/bin/perl

# $Id: make_kml.pl,v 1.1 2007-02-27 03:43:34 jaeger Exp $
#
# Makes a Google Earth .kml file from a GPS track log
#
# 17 February 2007

use strict;

use lib '/home/jaeger/src/bcfs/lib';
use Jaeger::GPS;

use POSIX qw(strftime);

print <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.1">
  <Document>
    <name>Jaeger Was Here</name>
    <description>These are the places Jaeger has been.</description>
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

my $last_date = undef;

my $last_point = undef;

foreach my $point (Jaeger::GPS->Select("1=1 order by date asc")) {
#foreach my $point (Jaeger::GPS->Select("date < 1107241200 order by date asc")) {
	if(defined($last_point) && $point == $last_point) {
		next;
	}

	my $this_date = strftime("%Y-%m-%d", localtime($point->date()));

	if($this_date ne $last_date) {
		if(defined $last_date) {
			print <<XML;
        </coordinates>
      </LineString>
    </Placemark>
XML
		}
		my $long_date = strftime("%A, %d %B %Y",
			localtime($point->date()));
		print <<XML;
    <Placemark>
      <name>$this_date</name>
      <description>Jaeger was here on $long_date</description>
      <styleUrl>#track</styleUrl>
      <LineString>
        <extrude>0</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>
XML
		$last_point = undef;
		$last_date = $this_date;
	}

	if(defined($last_point)) {
		my $timespan = $point->date() - $last_point->date();

		# If more than five minutes have elapsed since the last
		# recorded point, or this point is more than five kilometers
		# away, start a new track.
		if(($timespan > 300) || (($point - $last_point) > 5)) {
			print <<XML;
        </coordinates>
      </LineString>
      <LineString>
        <extrude>0</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>
XML
		}
	}

	print "          $point->{longitude},$point->{latitude}\n";

	$last_point = $point;
}

term_track();

print <<XML;
  </Document>
</kml>
XML

sub init_track {
	my $date = shift;

	print <<XML;
    <Placemark>
      <name>$date</name>
      <description>Jaeger was here on $date</description>
      <styleUrl>#track</styleUrl>
      <LineString>
        <extrude>0</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>
XML
}

sub term_track {
	print <<XML;
        </coordinates>
      </LineString>
    </Placemark>
XML
}
