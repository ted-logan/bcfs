package		Jaeger::Content;

#
# $Id: Content.pm,v 1.1 2003-01-10 06:56:45 jaeger Exp $
#

# Content-controlling code

# 28 October 2002
# Ted Logan <jaeger@festing.org>

use strict;

use Jaeger::Base;
use Jaeger::Lookfeel;

use Time::Local;
use Data::Dumper;

@Jaeger::Content::ISA = qw(Jaeger::Base);

sub table {
	return 'content';
}

# returns html for this object
sub _html {
	my $self = shift;

	return $self->lf()->content(
		title => $self->{label},
		timestamp => $self->{timestamp},
		body => $self->{value}
	);
}

sub _title {
	my $self = shift;

	return $self->{label};
}

sub _url {
	my $self = shift;

	return $Jaeger::Base::BaseURL . "/content.cgi?page=$self->{label}";
}

sub parent {
	my $self = shift;

	return $self->Select(label => $self->{parent});
}

sub sibblings {
	my $self = shift;

	if($self->{parent}) {
		return $self->Select(parent => $self->{parent});
	} else {
		return $self->Select('parent is null');
	}
}

sub children {
	my $self = shift;

	return $self->Select(parent => $self->{label});
}

sub Navbar {
	my $package = shift;

	my $lf = Jaeger::Base::Lookfeel();

	my @objects;

	if(ref $package) {
		# ascend from the current object to the top
		my $current = $package;

		# did we start with any children?
		foreach my $child ($current->children()) {
			push @objects, {
				title => $child->title(),
				url => $child->url()
			};
		}

		# make sure to sort the children
		@objects = sort {$a->{title} cmp $b->{title}} @objects;

		do {
			@objects = (
				{
					title => $current->title(),
					url => $current->url(),
					children => [@objects]
				}
			);

			# add the sibblings
			foreach my $sibbling ($current->sibblings()) {
				next if $sibbling->title() eq $current->title();
				push @objects, {
					title => $sibbling->title(),
					url => $sibbling->url()
				}
			}

			# sort everything
			@objects = sort {$a->{title} cmp $b->{title}} @objects;

			$current = $current->parent();
		} while(ref($current) eq 'Jaeger::Content');

#		warn Dumper(\@objects);

#		exit;

	} else {
		# populate with the top-level categories
		my @toplevel= $package->Select('parent is null order by label');
		foreach my $item (@toplevel) {
			push @objects, {
				title => $item->title(),
				url => $item->url()
			};
		}
	}

	my @content;
	foreach my $item (@objects) {
		push @content, $lf->content_link(
			current => (ref $package ? $package->title() : ''),
			%$item
		);
	}

	return @content;
}

1;
