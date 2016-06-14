package App::Transfer::Recipe::Transform::Row::Step;

# ABSTRACT: Base class for the row transformation step

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

has 'type' => (
    is       => 'ro',
    isa      => enum( [qw(split join copy batch lookup lookupdb)] ),
    required => 1,
);
has 'method' => ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform::Row::Step - Row transformation step

=head1 Synopsis

   my $steps = App::Transfer::Recipe::Transform::Row::Step->new(
      $self->recipe_data->{step},
   );

=head1 Description

Row transformation step abstract base class.  An object representing a
C<step> section of the type C<row> recipe transformations.

=head1 Interface

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Row::Step> object.

   my $steps = App::Transfer::Recipe::Transform::Row::Step->new(
      $self->recipe_data->{step},
   );

=head2 Attributes

=head3 C<type>

The transformation type identifier.  Each type has his required and
optional attributes.

Valid row transformation types:

=over

=item copy

=item split

=item join

=item batch

=item lookup

=item lookupdb

=back

=head3 C<method>

The name of the plugin method to be called for the transformation.

=head3 C<field_src>

The source field or fields.  For example the C<split> transformation
type has one source field (Str) and multiple destination fields
(Array).

=head3 C<field_dst>

The destination field or fields.  For example the C<join>
transformation type has multiple source fields (Array) and one
destination field (Str).

=head3 C<attributes>

Attributes that can be used to alter the behavior of the
transformation.

Action attributes:

=over

=item C<COPY>

Copy the value of the source field to the destination field.

=item C<MOVE>

Copy the value of the source field to the destination field and
nullify the source field.

=back

Modifier attributes:

=over

=item C<APPEND>

Append the new value to the existing (old) value.  The new string
takes the form: old string followed by a comma and a space followed by
the new value.  If there is no old value then only the new value is
used, without the comma and the space.

    <old_value, new_value> or <new_value>

=item C<APPENDSRC>

The new field value takes the form:

    <old_value, src_field_name: new_value> or <new_value>

=item C<REPLACE>

Replaces the current value of the field.

=item C<REPLACENULL>

Replaces the current value of the field only if it's NULL.

=back

=head3 C<separator>

Used only by the C<split> and C<join> row transformation types.  The
separator to be used by the C<split> or C<join> Perl functions.

For example:

  <step>
    type                = split
    separator           = ' '
    ...
  </step>

  <step>
    type                = join
    separator           = ', '
    ...
  </step>

=head3 C<datasource>

A dictionary type data structure.  Can be used for simple lookups when
a value must be replaced by another.

=head3 C<hints>

A dictionary type data structure.  Can be used to fix frequently made
user spelling mistakes in a database column.  For example when looking
for C<THIS> actually look for C<THAT>.

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
