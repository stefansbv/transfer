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

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_params',
);

sub _build_params {
    my $self = shift;
    my $p = {};
    $p->{field_src} = $self->field_src;
    $p->{field_dst} = $self->field_dst;
    $p->{limit}     = $self->limit;
    $p->{separator} = $self->separator;
    $p->{method}    = $self->method // 'split_field';
    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform::Row::Split - Row transformation step - split

=head1 Synopsis

   my $steps = App::Transfer::Recipe::Transform::Row::Split->new(
      $self->recipe_data->{step},
   );

Where the C<step> type is C<split>.

=head1 Description

An object representing a C<row> recipe transformations C<step> section
with the type attribute set to C<split>.

A recipe step example:

  # Use """ to preserve space, not "'"
  <step>
    type                = split
    separator           = ,
    field_src           = adresa
    method              = split_field
    field_dst           = localitate
    field_dst           = strada
    field_dst           = numarul
  </step>

=head1 Interface

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Row::Copy> object.

   my $steps = App::Transfer::Recipe::Transform::Row::Copy->new(
      $self->recipe_data->{step},
   );

Where the C<step> type is C<copy>.

=head2 Attributes

=head3 C<field_src>

The source field name string.

=head3 C<field_dst>

The destination field name string or array reference.

XXX Test with a string destination.

=head3 C<separator>

The separator to be used by the C<split> Perl function.

=head3 C<attributes>

XXX To do.

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

=head3 C<params>

Returns a hash reference with all the attributes.

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
