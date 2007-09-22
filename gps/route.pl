#!/usr/bin/perl

use strict;

use lib '/home/jaeger/src/bcfs-local/lib';
use Jaeger::GPS;

use XML::DOM;
use Math::Geometry::Planar;
use Math::NumberCruncher;

# load the waypoints
my %waypoints = load_waypoints("waypoints-2007-09-15.gpx");

# In the future, we should load the waypoint pairs we're interested in
# from a database or from a file.

my @pairs = (
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
	['MSA SHN JC', 'MSA FRN JC'],
	['MSA FRN JC', 'FERN JCT'],
	['MSA FRN J1', 'FERN JCT'],
	['FERN JCT', 'BEAR SADLE'],
	['BEAR SADLE', 'BEAR J1'],
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

# Pare down the waypoints according to the list of pairs we're interested in
my %waypoints_of_interest;
foreach my $pair (@pairs) {
	foreach my $wpt (@$pair) {
		$waypoints_of_interest{$wpt} = $waypoints{$wpt};
	}
}

my $last_point = undef;
my $last_waypoint = undef; # The name of the waypoint
my $last_waypoint_track = undef;
my $last_waypoint_distance = undef; # The distance the track was to the
	# waypoint, in km
my @track = ();

my $iter = Jaeger::GPS->Iterate("1=1 order by date asc");
#my $iter = Jaeger::GPS->Iterate("date > 1167634800 order by date asc");
while(my $point = $iter->next()) {
	if(defined($last_point) && $point == $last_point) {
		next;
	}

	if(defined($last_point)) {
		my $timespan = $point->date() - $last_point->date();

		if(($timespan > 300) || (($point - $last_point) > 5)) {
			# Start a new track
			$last_waypoint = undef;
			@track = ();
		}
	}

	push @track, $point;

	foreach my $waypoint (keys %waypoints_of_interest) {
#		print "Comparing $point with '$waypoint': $waypoints_of_interest{$waypoint}\n";
		my $distance = $point - $waypoints_of_interest{$waypoint};
		# If this waypoint is 10m or closer...
		if($distance <= 0.010) {
#			printf "Waypoint hit: '%s' %.2f m $point\n",
#				$waypoint, $distance * 1000.0;
			if($last_waypoint eq $waypoint) {
				if($distance < $last_waypoint_distance) {
					# This hit is closer
					$last_waypoint_track = $point;
					$distance = $last_waypoint_distance;
				}
			} else {
				# TODO This will always match the closest
				# approach to a ending waypoint, rather than
				# the closest approach.
				if(defined $last_waypoint) {
					# Try to match relevant waypoint pairs
					check_waypoint_pair($last_waypoint,
						$waypoint, @track);
=for later
					foreach my $pair (@pairs) {
						if($last_waypoint eq $pair[0]
					}
					print "Waypoint to waypoint hit:\n";
					printf "\t'%s' %.2f m $last_waypoint_track\n",
						$last_waypoint,
						$last_waypoint_distance * 1000.0;
					printf "\t'%s' %.2f m $point\n",
						$waypoint,
						$distance * 1000.0;
					print "\n";
=cut
				}
				$last_waypoint = $waypoint;
				$last_waypoint_track = $point;
				$last_waypoint_distance = $distance;
				@track = ();
			}
		}
	}

	$last_point = $point;
}

print "\n";
print "================================================================\n";
print " Creating routes\n";
print "================================================================\n";
print "\n";

open KML, ">routes.kml";

print KML <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.1">
  <Document>
    <name>Routes (demo)</name>
    <description>With any luck, this kml file will contain routes. Note that the Mesa trail/Shanahan junction doesn't register properly, apparently because the waypoint is not marked properly.</description>
    <Style id="track">
      <LineStyle>
        <color>c0000080</color>
        <width>2</width>
      </LineStyle>
    </Style>
    <Style id="route">
      <LineStyle>
        <color>c000c080</color>
        <width>4</width>
      </LineStyle>
    </Style>
XML

# Now that we have tracks attached to waypoint pairs, display them
foreach my $pair (@pairs) {
	print "\n------------------------------------------------\n";
	print "Waypoint pair: '$pair->[0]' <=> '$pair->[1]'\n";
	print "------------------------------------------------\n";

	print KML <<XML;
    <Folder>
      <name>'$pair->[0]' &lt;=&gt; '$pair->[1]'</name>
      <visibility>1</visibility>
      <open>0</open>
XML

	my @tracks;
	for(my $i = 2; $i < @$pair; $i++) {
		printf "\tTrack: %d points\n", scalar(@{$pair->[$i]});
		print "\t\tFirst: $pair->[$i]->[0]\n";
		print "\t\tLast: $pair->[$i]->[-1]\n";

		my $name = scalar(localtime $pair->[$i]->[0]->date());

		# Print raw points
		print KML <<XML;
      <Placemark>
        <name>$name</name>
	<styleUrl>#track</styleUrl>
	<LineString>
          <extrude>0</extrude>
          <tessellate>1</tessellate>
          <altitudeMode>clampToGround</altitudeMode>
          <coordinates>
XML

		foreach my $p (@{$pair->[$i]}) {
			print KML "            $p->{longitude},$p->{latitude}\n";
		}

		print KML <<XML;
          </coordinates>
	</LineString>
      </Placemark>
XML

		my @cleaned_up_track = clean_up_track(@{$pair->[$i]});
		push @tracks, \@cleaned_up_track;

=for before
		print KML <<XML;
      <Placemark>
        <name>$name (cleaned up)</name>
	<styleUrl>#route</styleUrl>
	<LineString>
          <extrude>0</extrude>
          <tessellate>1</tessellate>
          <altitudeMode>clampToGround</altitudeMode>
          <coordinates>
XML

		foreach my $p (@cleaned_up_track) {
			print KML "            $p->{longitude},$p->{latitude}\n";
		}

		print KML <<XML;
          </coordinates>
	</LineString>
      </Placemark>
XML
=cut
	}

	# Print the completed route
	print KML <<XML;
      <Placemark>
        <name>'$pair->[0]' &lt;=&gt; '$pair->[1]'</name>
	<styleUrl>#route</styleUrl>
	<LineString>
          <extrude>0</extrude>
          <tessellate>1</tessellate>
          <altitudeMode>clampToGround</altitudeMode>
          <coordinates>
XML

	foreach my $p (find_common_route(@tracks)) {
		print KML "            $p->{longitude},$p->{latitude}\n";
	}

	print KML <<XML;
          </coordinates>
	</LineString>
      </Placemark>
XML

	print KML <<XML;
    </Folder>
XML
}

print KML <<XML;
  </Document>
</kml>
XML

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

sub check_waypoint_pair {
	my $wp0 = shift;
	my $wp1 = shift;

	print "Considering waypoint pair '$wp0' <=> '$wp1'\n";
	print "\t@_[0]\n";
	print "\t@_[-1]\n";

	foreach my $pair (@pairs) {
		if($pair->[0] eq $wp0 && $pair->[1] eq $wp1) {
			# Forward waypoint pair match
			print "\tForward waypoint match\n";
			push @$pair, [@_];
		} elsif($pair->[0] eq $wp1 && $pair->[1] eq $wp0) {
			# Reverse waypoint pair match
			push @$pair, [reverse @_];
			print "\tReverse waypoint match\n";
		}
	}
}

# Removes overlapping track points
# (This is an expensive, O(n^2) operation)
#
# Input: List containing the waypoints
# Output: Array containing the waypoints, cleaned up a bit
sub clean_up_track {
	my @track_out;

	OUTER: for(my $i = 0; $i < @_; $i++) {
		for(my $j = $i + 1; $j < @_; $j++) {
			# Compare this point to every following point
			if($_[$i] == $_[$j]) {
				# Discard all points between $i and $j
				$i = $j - 1;
				next OUTER;
			}

			# Compare this point with the line drawn between
			# adjacent points

			# Make sure we have a next point
			if(($j + 1 < @_) && ($i + 1 < $j)) {
				my $pt = intersect(
					$_[$i], $_[$i + 1],
					$_[$j], $_[$j + 1]);
				if($pt) {
					if($pt->{latitude} > 41 || $pt->{latitude} < 39 || $pt->{longitude} > -104 || $pt->{longitude} < -106) {
						print "p1: $_[$i]\n";
						print "p2: $_[$i + 1]\n";
						print "p3: $_[$j]\n";
						print "p4: $_[$j + 1]\n";
					}
					print "Got intersecting point: $pt\n";
					print "\n";
					push @track_out, @_[$i];
					push @track_out, $pt;
					$i = $j;
					next OUTER;
				}
			}
		}

		push @track_out, @_[$i];
	}

	return @track_out;
}

# Given a series of tracks along the same route, find the most common path
# (This function is the reason we're here.)
sub find_common_route {
	if(@_ == 1) {
		return @{$_[0]};
	}
	if(@_ == 0) {
		return undef;
	}

	# More than one input track -- this is the interesting case.

	my @points;

	# Get the starting point
	foreach my $track (@_) {
		push @points, shift @$track;
	}

	my @route;

	MAIN: while(1) {
		print "\nfind_common_route: Averaging ", scalar(@points),
			" points:\n";
		foreach my $point (@points) {
			print "\t$point\n";
		}

		# The next point is the average of the points we entered
		# the loop with
		my $next_point = new Jaeger::GPS;
		$next_point->{longitude} = Math::NumberCruncher::Mean(
			[map {$_->longitude()} @points]
		);
		$next_point->{latitude} = Math::NumberCruncher::Mean(
			[map {$_->latitude()} @points]
		);
		push @route, $next_point;

		print "\t$next_point\n";

		# Loop termination condition: Make sure each input track
		# has at least one point left
		foreach my $track (@_) {
			last MAIN unless @$track;
		}

		@points = ();

		# Find the closest track point to the current point.
		# TODO we may be able to get slightly better results by
		# iterating through _all_ track points; this is already
		# an n^2 algorithm (or worse), but I'm not yet convinced
		# this would be worth it.
		my $distance = undef;
		my $min_index = undef;
		for(my $i = 0; $i < @_; $i++) {
			my $d = $_[$i]->[0] - $next_point;
			if(!defined($distance) || $d < $distance) {
				$distance = $d;
				$min_index = $i;
			}
		}

		my $trigger_point = shift @{$_[$min_index]};
		push @points, $trigger_point;

		print "\tTrack $min_index: ", scalar(@{$_[$min_index]}),
			" points left\n";

		for(my $i = 0; $i < @_; $i++) {
			unless($i == $min_index) {
				# Find the point _on the entire track_
				# closest to the trigger point. Discard all
				# track points before the new closest point.
				push @points, find_closest_point($trigger_point,
					$_[$i]);
				print "\tTrack $i: ", scalar(@{$_[$i]}),
					" points left\n";

			}
		}

		# That's it -- we have our set of points to average and get
		# the next route point.
	}

	return @route;
}

# find_closest_point(p, [p1, p2, p3, ... pn])
# Returns the closest point on the track, and removes the points in the
# track before the closest point
sub find_closest_point {
	my ($p, $track) = @_;

	my $distance = undef;
	my $min_index = -1;
	my $closest_point = $track->[0];

	for(my $i = 1; $i < @$track; $i++) {
		my $px = nearest_to_segment($track->[$i - 1], $track->[$i], $p);
		my $d = $px - $p;
		if(!defined($distance) || $distance >= $d) {
			$distance = $d;
			if($px == $track->[$i]) {
				$min_index = $i;
			} else {
				$min_index = $i - 1;
			}
			$closest_point = $px;
		}
	}

	# Remove points in the track prior to the closest point
	if($min_index > -1) {
		splice @$track, 0, $min_index + 1;
	}

	return $closest_point;
}

sub min {
	return ($_[0] < $_[1]) ? $_[0] : $_[1];
}

sub max {
	return ($_[0] > $_[1]) ? $_[0] : $_[1];
}

# Determines whether two line segments intersect. Returns the point if it
# exists; otherwise, returns undef.
# Arguments: p1, p2, p3, p3
# The two line segments are p1-p2 and p3-p4
#
# This implementation is based on _Mastering Algorithms with C_, chapter 17.
sub intersect {
	my ($p1, $p2, $p3, $p4) = @_;

	# Assume we can use the longitude and latitude as if they were planar.
	# Technically they're arcs, not lines, but since we're dealing with
	# distances on the order of less than tens of meters, I think it's
	# a safe assumption. If this proves inaccurate, we may want to consider
	# UTM.
	my ($x1, $y1) = ($p1->longitude(), $p1->latitude());
	my ($x2, $y2) = ($p2->longitude(), $p2->latitude());
	my ($x3, $y3) = ($p3->longitude(), $p3->latitude());
	my ($x4, $y4) = ($p4->longitude(), $p4->latitude());

	# Perform the quick rejection test
	# (Make sure the bounding boxes intersect)
	return undef unless max($x1, $x2) >= min($x3, $x4);
	return undef unless max($x3, $x4) >= min($x1, $x2);
	return undef unless max($y1, $y2) >= min($y3, $y4);
	return undef unless max($y3, $y4) >= min($y1, $y2);

	# Perform the straddle test
	my $z1 = ($x3 - $x1) * ($y2 - $y1) - ($y3 - $y1) * ($x2 - $x1);
	if($z1 < 0) {
		$z1 = -1;
	} elsif($z1 > 0) {
		$z1 = 1;
	} else {
		$z1 = 0;
	}
	my $z2 = ($x4 - $x1) * ($y2 - $y1) - ($y4 - $y1) * ($x2 - $x1);
	if($z2 < 0) {
		$z2 = -1;
	} elsif($z2 > 0) {
		$z2 = 1;
	} else {
		$z2 = 0;
	}

	return undef unless $z1 == 0 || $z2 == 0 || $z1 != $z2;

	# The line segments intersect. Now we need to find out where.
	my ($m1, $b1) = slope_intercept($x1, $y1, $x2, $y2);
	my ($m2, $b2) = slope_intercept($x3, $y3, $x4, $y4);

	if(!defined($m1) && !defined($m2)) {
		# Lines are parallel and vertical.
		# We must determine whether p1 or p2 lies within p3 and p4,
		# using the y coordinate.
		if($y1 >= min($y3, $y4) && $y1 <= max($y3, $y4)) {
			return $p1;
		} else {
			return $p2;
		}
	}

	if($m1 == $m2) {
		# Lines are parallel (and not vertical); since we've
		# already determined that they do intersect, they must
		# be colinear.
		if($p1 == $p3 || $p1 == $p4) {
			return $p1;
		}
		if($p2 == $p3 || $p2 == $p4) {
			return $p2;
		}
		# None of the points actually equal. We must determine
		# whether p1 or p2 lies within p3 and p4, using the x
		# coordinate.
		if($x1 >= min($x3, $x4) && $x1 <= max($x3, $x4)) {
			return $p1;
		} else {
			return $p2;
		}
	}

	my $point = new Jaeger::GPS;

	unless(defined($m1)) {
		# The first line is vertical. Determine the y coordinate where
		# the second line hits $x1.
		print "Intersect: First line is vertical\n";
		$point->{longitude} = $x1;
		$point->{latitude} = $m2 * $x1 + $b2;
		return $point;
	}

	unless(defined($m2)) {
		# The second line is vertical. Determine the y coordinate where
		# the first line hits $x3.
		print "Intersect: Second line is vertical\n";
		$point->{longitude} = $x3;
		$point->{latitude} = $m1 * $x3 + $b1;
		return $point;
	}

	printf "Intersect: m1=%.5f b1=%.5f; m2=%.5f b2=%.5f\n",
		$m1, $b1, $m2, $b2;

	# The equations I have don't have the minus in front of the x
	# coordinate. However, when I add it, everything works fine.
	$point->{longitude} = - ($b2 - $b1) / ($m2 - $m1);
	$point->{latitude} = $m1 * $point->{longitude} + $b1;
	return $point;
}

# Returns the slope and y-intercept of the line containing the two points.
# Arguments: x1, y1, x2, y2
sub slope_intercept {
	my ($x1, $y1, $x2, $y2) = @_;
#	printf "Calculating slope-intercept for (%.5f, %.5f) - (%.5f, %.5f)\n",
#		$x1, $y1, $x2, $y2;
	if($x1 == $x2) {
		# Line is vertical -- slope is infinite, y-intercept
		# is undefined.
		return undef;
	}
	my $m = ($y2 - $y1) / ($x2 - $x1);
	my $b = $y1 - $m * $x1;
#	printf "\tm=%.5f b=%.5f\n", $m, $b;
	return ($m, $b);
}

# nearest_to_segment(p1, p2, p3)
# Returns the point on the line segment p1-p2 nearest to point p3
sub nearest_to_segment {
	my ($p1, $p2, $p3) = @_;

	# Construct point (x4, y4) such that the line p3-p4 is perpindicular
	# to the line p1-p2
	my ($m, $b) = slope_intercept(
		$p1->longitude(), $p1->latitude(),
		$p2->longitude(), $p2->latitude()
	);

	my $k = 0.1;
	my ($x4, $y4);
	if(defined $m) {
		if($m == 0) {
			# p1-p2 is horizontal; p3-p4 is vertical
			$x4 = $p3->longitude();
			$y4 = $p3->latitude() + $k;
		} else {
			# General case
			$x4 = $p3->longitude() + $k * (0 - $m);
			$y4 = $p3->latitude() + $k * 1 / (0 - $m);
		}
	} else {
		# p1-p2 is vertical; p3-p4 is horizontal
		$x4 = $p3->longitude() + $k;
		$y4 = $p3->latitude();
	}

	# Use Math::Geometry::Planar to determine the intersect, if any
	my $intersect = SegmentLineIntersection([
		[$p1->longitude(), $p1->latitude()],
		[$p2->longitude(), $p2->latitude()],
		[$p3->longitude(), $p3->latitude()],
		[$x4, $y4]
	]);

	if($intersect) {
		my $point = new Jaeger::GPS;
		$point->{longitude} = $intersect->[0];
		$point->{latitude} = $intersect->[1];
		return $point;
	}

	# Determine which end point of the line segment is closer
	# to the point we care about
	my $d1 = $p1 - $p3;
	my $d2 = $p2 - $p3;

	if($d1 > $d2) {
		return $p2;
	} else {
		return $p1;
	}
}
