package		Jaeger::Yoda;

#
# $Id: Yoda.pm,v 1.3 2003-10-01 01:23:23 jaeger Exp $
#

# For voyerstic pleasure, shows Yoda's gas mileage

# 22 July 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

@Jaeger::Yoda::ISA = qw(Jaeger::Base);

@Jaeger::Yoda::Params = qw(date station city state mileage ppg gal total valid);

# returns a new object
sub new {
	my $package = shift;

	my $self = $package->SUPER::new();

	$self->{title} = 'Yoda Gas Mileage';
  
	return $self;
}

sub insert {
	my $self = shift;
	my %params = @_;

	foreach my $p (@Jaeger::Yoda::Params) {
		unless($params{$p}) {
			warn "Yoda.pm: Rejected empty parameter $p\n";
			return 0;
		}
	}

	my $sql = 'insert into yoda values (' .
		join(', ', map {$self->{dbh}->quote($params{$_})}
			@Jaeger::Yoda::Params) . ')';

	$self->{dbh}->do($sql);

	return 1;
}

# returns html for this object
sub _html {
	my $self = shift;

	if($self->{submit}) {
		return $self->lf()->yoda_submit();
	} else {
		# do something more complicated

		my @content;

		push @content, $self->lf()->yoda_header();

		my $sql = "select * from yoda order by mileage";
		my $sth = $self->{dbh}->prepare($sql);
		$sth->execute();

		my $last_row;

		while(my $row = $sth->fetchrow_hashref()) {
			if(ref $last_row) {
				$row->{miles} =
					$row->{mileage} - $last_row->{mileage};
				if($row->{valid}) {
					$row->{mpg} =
						$row->{miles} / $row->{gal};
				}
			}
			push @content, $self->lf()->yoda_item(%$row);
			$last_row = $row;
		}

		my $user = Jaeger::User->Login();
		if($user && $user->login() eq 'jaeger') {
			push @content, $self->lf()->yoda_main();
		}

		return join '', @content;
	}
}

1;
