package Jaeger::Base;

#
# $Id: Base.pm,v 1.2 2002-09-02 05:14:03 jaeger Exp $
#

#	Copyright (c) 1999-2002 Ted Logan (jaeger@festing.org)

#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published
#	by the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.  Please see the COPYING file
#	included in this distribution.

#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.

#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA


# base for all jaegerfesting modules: creates a database connection unless one 
# has been passed to us, and allow accessing internal stuff via AUTOLOAD

# 18 August 1999
# Ted Logan

# modified 28 May 2000 for jaegerfesting

# updated 18 May 2002

use strict;
use DBI;
use Carp qw(cluck carp confess);

use Jaeger::Lookfeel;

#$Jaeger::Base::BaseURL = 'http://jaeger.festing.org';
$Jaeger::Base::BaseURL = '';

$Jaeger::Base::Pgdbh = DBI->connect("DBI:Pg:dbname=jaeger", "", "")
    	or warn "unable to connect to pg database";

@Jaeger::Base::Months = qw(blah January February March April May June July August September October November December);
@Jaeger::Base::Weekdays = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

sub new {
	my $package = shift;
	my $self = {};

	$self->{dbh} = $Jaeger::Base::Pgdbh;

	bless $self, $package;
	return $self;
}

sub AUTOLOAD {
	my $obj = shift;
	my $varible = $Jaeger::Base::AUTOLOAD;
	$varible =~ s/.*:://;
	return if $varible eq 'DESTROY';
	if($varible =~ /^_/) {
		return;
	}
	my $value = shift;

	if(exists $obj->{$varible}) {
		if(defined $value) {
			$obj->{$varible} = $value;
		}
		return $obj->{$varible};
	} else {
		unshift @_, $value;

		# maybe there's an underscored function to do the right thing
		# we do this to only select things we actually need
		my $value = eval "\$obj->_$varible(\@_)";
		if($@) {
			carp "property $varible not found ($obj) ($@)";
		} else {
			return $value;
		}
	}
}

# returns a look and feel object
sub _lf {
	my $self = shift;

	return $self->{lf} = new Jaeger::Lookfeel;
}

1;
