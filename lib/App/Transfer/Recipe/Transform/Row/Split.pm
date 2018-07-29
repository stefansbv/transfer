package App::Transfer::Recipe::Transform::Row::Split;

# ABSTRACT: Row transformation step - split

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

extends 'App::Transfer::Recipe::Transform::Row::Step';

has 'separator' => ( is => 'ro', isa => 'Str', required => 1 );
has 'field_src' => ( is => 'ro', isa => 'Str', required => 1 );

has 'field_dst' => (
    is       => 'ro',
    isa      => 'ArrayRefFromStr',
    coerce   => 1,
    required => 1,
);

has 'limit' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my $self = shift;
        return scalar @{ $self->field_dst };
    },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

App::Transfer::Recipe::Transform::Row::Split - Row transformation step - split

=head1 SYNOPSIS

  my $step = App::Transfer::Recipe::Transform::Row::Split->new(
      type      => 'split',
      separator => ",",
      field_src => 'address',
      method    => 'split_field',
      field_dst => [qw{locality street number}],
  );
  $trafo->type_split( $step, $record, $logstr );

Where the C<step> type is C<split>.

=head1 DESCRIPTION

An object representing a C<row> recipe transformations C<step> section
with the type attribute set to C<split>.

A recipe step example:

  # Use """ to preserve space, not "'"
  <step>
    type                = split
    separator           = ,
    field_src           = addres
    method              = split_field
    field_dst           = locality
    field_dst           = street
    field_dst           = number
  </step>

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 C<field_src>

The source field name string.

=head3 C<field_dst>

The destination field name string or array reference.

XXX Test with a string destination.

=head3 C<separator>

The separator to be used by the C<split> Perl function.

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

=head3 C<limit>
split
The number of destination fields, used as the third parameter for the
C<split> function.

=head2 INSTANCE METHODS

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Row::Split> object, where the
C<step> type is C<split>.

=cut
