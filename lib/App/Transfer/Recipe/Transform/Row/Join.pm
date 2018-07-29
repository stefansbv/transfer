package App::Transfer::Recipe::Transform::Row::Join;

# ABSTRACT: Row transformation step - join

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

extends 'App::Transfer::Recipe::Transform::Row::Step';

has 'separator' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'field_src' => (
    is       => 'ro',
    isa      => 'ArrayRefFromStr',
    coerce   => 1,
    required => 1,
);

has 'field_dst' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

App::Transfer::Recipe::Transform::Row::Join - Row transformation step - join

=head1 SYNOPSIS

  my $step = App::Transfer::Recipe::Transform::Row::Join->new(
      type      => 'join',
      separator => ", ",
      field_src => [qw{locality street number}],
      method    => 'join_fields',
      field_dst => 'address',
  );
  $trafo->type_join( $step, $record, $logstr );

Where the C<step> type is C<join>.

=head1 DESCRIPTION

An object representing a C<row> recipe transformations C<step> section
with the type attribute set to C<join>.

A recipe step example:

  # Use """ to preserve space, not "'"
  <step>
    type                = join
    separator           = ", "
    field_src           = locality
    field_src           = street
    field_src           = number
    method              = join_fields
    field_dst           = address
  </step>

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 C<field_src>

The source field names array reference.

=head3 C<field_dst>

The destination field name string.

XXX Test with a string destination.

=head3 C<separator>

The separator to be used by the C<join> Perl function.

=head3 C<attributes>

Attributes to alter the behavior of the transformation.

Valid attributes:

=over

=item C<APPEND>

=item C<APPENDSRC>

=item C<COPY>

=item C<MOVE>

=item C<REPLACE>

=item C<REPLACENULL>

=back

=head2 INSTANCE METHODS

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Row::Join> object, where the
C<step> type is C<join>.

=cut
