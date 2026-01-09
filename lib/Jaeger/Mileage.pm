package		Jaeger::Mileage;

#
# $Id: Mileage.pm,v 1.1 2007-07-08 19:02:05 jaeger Exp $
#

# For voyerstic pleasure, shows gas mileage for my vehicles

# 22 July 2002: Began life displaying Mileage's mileage
# 8 July 2007: Expanded to include other vehicles in my posession
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;
use Jaeger::Vehicle;

use Log::Any qw($log), default_adapter => 'Stderr';

@Jaeger::Mileage::ISA = qw(Jaeger::Base);

@Jaeger::Mileage::Params = qw(vehicle_id date station city state mileage ppg gal total valid);

# returns a new object
sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	my $vehicle = shift;

	# Three possibilities for vehicle: Name, id, or object
	if(ref($vehicle) =~ /Vehicle/) {
		$self->{vehicle} = $vehicle;
	} elsif($vehicle =~ /^\d+$/) {
		$self->{vehicle} = Jaeger::Vehicle->new_id($vehicle);
		unless($self->{vehicle}) {
			$log->error("Unable to find vehicle with id $vehicle");
			return undef;
		}
	} else {
		$self->{vehicle} = Jaeger::Vehicle->Select(name => $vehicle);
		unless($self->{vehicle}) {
			$log->error("Unable to find vehicle with name $vehicle");
			return undef;
		}
	}

	$self->{title} = $self->{vehicle}->name() . " Gas Mileage";
  
	return $self;
}

sub insert {
	my $self = shift;
	my %params = @_;

	foreach my $p (@Jaeger::Mileage::Params) {
		unless($params{$p}) {
			$log->error("Mileage.pm: Rejected empty parameter $p");
			return 0;
		}
	}

	my $sql = 'insert into mileage values (' .
		join(', ', map {$self->dbh()->quote($params{$_})}
			@Jaeger::Mileage::Params) . ')';

	$self->dbh()->do($sql);

	return 1;
}

# returns html for this object
sub _html {
	my $self = shift;

	if($self->{submit}) {
		return $self->lf()->yoda_submit(
			vehicle_id => $self->vehicle()->id(),
			vehicle_name => $self->vehicle()->name(),
		);
	} else {
		# do something more complicated

		my @content;
		my @mpg;

		push @content, $self->lf()->yoda_header();

		my $sql = "select * from mileage where vehicle_id = " .
			$self->vehicle()->id() . " order by mileage";
		my $sth = $self->dbh()->prepare($sql);
		$sth->execute();

		my $last_row;

		while(my $row = $sth->fetchrow_hashref()) {
			if(ref $last_row) {
				$row->{miles} =
					$row->{mileage} - $last_row->{mileage};
				if($row->{valid}) {
					$row->{mpg} =
						$row->{miles} / $row->{gal};
					push @mpg, $row->{mpg};
				}
			}
			push @content, $self->lf()->yoda_item(%$row);
			$last_row = $row;
		}

		# Determine the median MPG
		@mpg = sort {$a <=> $b} @mpg;
		my $median_mpg;
		if((scalar(@mpg) % 2) == 1) {
			# List is odd; pick the middle element
			my $middle = (scalar(@mpg) - 1) / 2;
			$median_mpg = $mpg[$middle];
		} else {
			# List is even; average the middle two elements
			my $middle = scalar(@mpg) / 2;
			$median_mpg = ($mpg[$middle - 1] + $mpg[$middle]) / 2;
		}

		push @content, "<tr>";
		push @content, "<td colspan=\"8\" align=\"right\">Median</td>";
		push @content, "<td align=\"right\">";
		push @content, sprintf("%.2f", $median_mpg);
		push @content, "</td></tr>\n";

		my $user = Jaeger::User->Login();
		if($user && $user->status() >= 25) {
			push @content, $self->lf()->yoda_main(
				vehicle_id => $self->vehicle()->id(),
			);
		}

		my @html;
		push @html, "<h1>$self->{title}</h1>\n";
		push @html, "<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\"><tr>\n";
		foreach my $vehicle (Jaeger::Vehicle->Select("1=1 order by id")) {
			push @html, "<td><center>\n";
			if($vehicle->id() == $self->vehicle()->id()) {
				push @html, "<b>";
			} else {
				push @html, "<a href=\"yoda.cgi?vehicle_id=",
					$vehicle->id(), "\">";
			}
			push @html, $vehicle->name();
			if($vehicle->id() == $self->vehicle()->id()) {
				push @html, "</b>\n";
			} else {
				push @html, "</a>\n";
			}
			push @html, "<br/>\n";
			push @html, "<i>", $vehicle->description(), "</i>\n";
			push @html, "</center></td>\n";
		}
		push @html, "</tr></table>\n";
		push @html, "<br/>\n";

		push @html, $self->lf()->yoda_table(
			data => join('', @content),
		);

		return join '', @html;
	}
}

1;
