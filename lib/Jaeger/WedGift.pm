package		Jaeger::WedGift;

#
# $Id: WedGift.pm,v 1.1 2004-11-12 23:19:51 jaeger Exp $
#

# Display and edit wedding gifts

# Created  22 July 2002 as Yoda.pm
# Borrowed 29 July 2002 for WedGift.pm
#
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

@Jaeger::WedGift::ISA = qw(Jaeger::Base);

@Jaeger::WedGift::Params = qw(name address gift arrived note_sent side);

%Jaeger::WedGift::Side = (
	10 => "Gem's Friends",
	11 => "Stone Family/Friends",
	20 => "Ted's Friends",
	21 => "Logan Family/Friends",
);

sub table {
	return 'gifts';
}

# returns a new object
sub new {
	my $package = shift;

	my $self = $package->SUPER::new(@_);

	$self->{title} = 'Gem and Ted\'s Wedding Gifts';
  
	return $self;
}

sub insert {
	my $self = shift;

	my $q = $self->query();

	foreach my $param (@Jaeger::WedGift::Params) {
		if($q->param($param)) {
			$self->{$param} = $q->param($param);
		} else {
			$self->{$param} = undef;
		}
	}

	$self->{ignore} = $q->param('ignore') ? 'true' : 'false';

	$self->update();

	print $q->redirect('http://jaeger.festing.org/presents.cgi');
	exit;
}

# returns html for this object
sub _html {
	my $self = shift;

	if(defined $self->{id}) {
		# edit or insert a wedding gift

		return $self->lf()->gift_edit(%$self);

	} else {
		# show the epic list of wedding gifts

		my $sort = $self->query()->param('sort');
		unless($sort) {
			$sort = 'name';
		}

		my @content;

		push @content, $self->lf()->gift_header('sort' => $sort);

		foreach my $gift (Jaeger::WedGift->Select("1=1 order by $sort"))
		{
			push @content, $self->lf()->gift_item(%$gift);
		}

		push @content, $self->lf()->gift_main();

		return join '', @content;
	}
}

sub printer {
	my $self = shift;

	my @gifts = Jaeger::WedGift->Select("note_sent is null and not ignore order by name");

	my @content;

	foreach my $gift (@gifts) {
		push @content, $self->lf()->gift_print_item(%$gift);
	}

	return $self->lf()->gift_print(
		gifts => join('', @content),
		written => Jaeger::WedGift->Count('note_sent is not null'),
		unwritten => scalar(@gifts),
	);
}

package Jaeger::Lookfeel;

# wedding gift stuff

sub _gift_item {
	my $self = shift;
	my %params = @_;

	$params{address} =~ s/\n/<br>\n/g;
	$params{gift} =~ s/\n/<br>\n/g;
	$params{side} = $Jaeger::WedGift::Side{$params{side}};

	if($params{ignore} && !$params{note_sent}) {
#		$params{note_sent} = '- - - - - -';
		$params{note_sent} = '<hr>';
	}

	foreach my $p (qw(address note_sent)) {
		unless($params{$p}) {
			$params{$p} = '&nbsp;';
		}
	}

	return %params;
}

sub _gift_print_item {
	my $self = shift;
	return $self->_gift_item(@_);
}

sub _gift_edit {
	my $self = shift;
	my %params = @_;

	if($params{side}) {
		$params{"$params{side}_select"} = 'selected';
	} else {
		$params{'21_select'} = 'selected';
	}

	$params{today} = $self->now();

	$params{ignore} = $params{ignore} ? 'checked' : '';

	return %params;
}

sub _gift_print {
	my $self = shift;
	my %params = @_;

	# get a quote
	my $fortune = new Fortune;
	$fortune->read('/home/jaeger/text/quotes/quotes');

	$params{quote} = $fortune->quote();
	$params{quote} =~ s/\n/<br>\n/g;

	return %params;
}

1;
