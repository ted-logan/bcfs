package		Jaeger::Lookfeel;

#
# $Id: Lookfeel.pm,v 1.1 2002-05-19 22:56:30 jaeger Exp $
#

#	Copyright (c) 1999-2002 Ted Logan (jaeger@festing.org)

# 06 May 1999 Ted Logan <jaeger@festing.org>
# modified 07 June 1999 for x13
# modified 29 August 1999 to use x13::Base
# modified 28 May 2000 for jaegerfesting
# updated 18 May 2002

use strict;

use Jaeger::Base;

use Fortune;

@Jaeger::Lookfeel::ISA = qw(Jaeger::Base);

@Jaeger::Lookfeel::KeepParams = qw(what id label year);

sub new {
	my $package = shift;
	my $self = $package->SUPER::new(@_);

	$self->{static} = undef;

	return $self;
}

# grabs the appropiate field from the look and feel table
sub _lookfeel {
	my $self = shift;
	my $section = shift;

	my $sql = "select value from lookfeel where label = '$section'";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute();
	return ($sth->fetchrow_array)[0];
}

sub AUTOLOAD {
	my $self = shift;
	my $page = $Jaeger::Lookfeel::AUTOLOAD;
	$page =~ s/.*://;
	return if $page eq "DESTROY";
	return @_ if $page =~ /^_/;

	if(my $content = $self->_lookfeel($page)) {
		# we might have a section-specific thing we need to do
		my %params = eval "\$self->_$page(\@_)";
		unless(%params) {
			%params = @_;
		}

		foreach my $p (keys %params) {
			$content =~ s/---$p---/$params{$p}/g;
		}

		$content =~ s/---\w*?---//g;
		return $content;
	} else {
		# content isn't in database; pass method on to master class
		return undef;
	}
}

# internal subs that manipulate the paramaters where necessary

sub _changelog {
	my $self = shift;

	my %params = @_;

	if($params{title}) {
		$params{title} = $self->changelog_title(
			title => $params{title}
		);
	}

	if($params{time_begin} && $params{time_end} &&
			($params{time_begin} ne $params{time_end})) {
		$params{timestamp} = $self->changelog_timeboth(
			time_begin => $params{time_begin},
			time_end => $params{time_end}
		);
	} elsif($params{time_begin}) {
		$params{timestamp} = $self->changelog_timebegin(
			time_begin => $params{time_begin}
		);
	}

	return %params;
}

1;
