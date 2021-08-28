#!/usr/bin/perl

# $Id: make_kml.pl,v 1.4 2008-04-07 00:50:01 jaeger Exp $
#
# Makes a Google Earth .kml file from a GPS track log
#
# 17 February 2007

use strict;

use lib '/home/jaeger/src/bcfs/lib';
use Jaeger::GPS;
use Jaeger::Photo;

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
    <Style id="photo">
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/pal4/icon46.png</href>
        </Icon>
      </IconStyle>
    </Style>
XML

my $last_date = undef;
my $last_month = undef;
my $last_year = undef;

my $last_point = undef;

foreach my $point (Jaeger::GPS->Select("1=1 order by date asc")) {
#foreach my $point (Jaeger::GPS->Select("date < 1107241200 order by date asc")) {
	if(defined($last_point) && $point == $last_point) {
		next;
	}

	my $this_date = strftime("%Y-%m-%d (%A)", localtime($point->date()));
	my $this_month = strftime("%B %Y", localtime($point->date()));
	my $this_year = strftime("%Y", localtime($point->date()));

	if($this_date ne $last_date) {
		if(defined $last_date) {
			print <<XML;
          </coordinates>
        </LineString>
      </MultiGeometry>
    </Placemark>
XML
		}

		if($this_month ne $last_month) {
			if(defined $last_month) {
				print <<XML;
    </Folder> <!-- month -->
XML
			}
			if($this_year ne $last_year) {
				if(defined $last_year) {
					print <<XML;
    </Folder> <!-- year -->
XML
				}

				print <<XML;
    <Folder>
      <name>$this_year</name>
XML
				$last_year = $this_year;
			}

			print <<XML;
    <Folder>
      <name>$this_month</name>
XML
			$last_month = $this_month;
		}

		print <<XML;
    <Placemark>
      <name>$this_date</name>
      <styleUrl>#track</styleUrl>
      <MultiGeometry>
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

# Show photos that have been geotagged
print <<XML;
    <Folder>
      <name>Geotagged photos</name>
XML
my @photos = Jaeger::Photo->Select("latitude is not null and longitude is not null and not hidden order by date");
foreach my $photo (@photos) {
	my $date = $photo->date_format();
	my $url = $photo->url();
	$photo->{size} = '640x480';
	my $thumbnail = $photo->image_url();
	print <<XML;
    <Placemark>
      <styleUrl>#photo</styleUrl>
      <description>
        <![CDATA[
          <p>$photo->{description}</p>
          <p><i>$date</i></p>
	  <a href="$url"><img src="$thumbnail" /></a>
        ]]>
      </description>
      <Point>
        <coordinates>$photo->{longitude},$photo->{latitude}</coordinates>
      </Point>
    </Placemark>
XML
}

print <<XML;
  </Folder> <!-- photos -->
  </Document>
</kml>
XML

sub term_track {
	print <<XML;
          </coordinates>
        </LineString>
      </MultiGeometry>
    </Placemark>
    </Folder> <!-- month -->
    </Folder> <!-- year -->
XML
}
