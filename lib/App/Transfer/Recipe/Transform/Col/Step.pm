package App::Transfer::Recipe::Transform::Col::Step;

# ABSTRACT: Column transformation step

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

has 'field' => ( is => 'ro', isa => 'Str' );

has 'input' => ( is => 'ro', isa => 'Str' );

has 'type' => (
    is       => 'ro',
    isa      => enum( [qw(transform default_value)] ),
    required => 0,
    default  => sub {
        return 'transform';
    },
);

has 'method' => (
    is     => 'ro',
    isa    => 'ArrayRefFromStr',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

App::Transfer::Recipe::Transform::Col::Step - Column transformation step

=head1 SYNOPSIS

   my $steps = App::Transfer::Recipe::Transform::Col::Step->new(
      $self->recipe_data->{step},
   );

=head1 DESCRIPTION

An object representing a C<step> section of the type C<column> recipe
transformations.

=head1 INTERFACE

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Col::Step> object.

   my $steps = App::Transfer::Recipe::Transform::Col::Step->new(
      $self->recipe_data->{step},
   );

=head2 ATTRIBUTES

=head3 C<field>

A string attribute representing the name of the field (column).

=head3 C<input>

Idea:

Alternative value for the record.  If this attribute is defined the
value passed to the plugin is NOT the value fo the C<field> but the
value of the C<input>.

Goal: make default values for fields from other info, for example the
name of the input file.  Usefull for transfering data from files to
databases, when we have a seperate file for every month.

Not implemented! TODO!

=head3 C<method>

An array reference with the name(s) of the plugin method to be called
for the transformation.  If there is more than one method, all methods
will be called in order and the result of the first is passed to the
next, and so on.
