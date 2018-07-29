package App::Transfer::Recipe::Transform::Row::Copy;

# ABSTRACT: Row transformation step - copy

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

extends 'App::Transfer::Recipe::Transform::Row::Step';

has 'field_src'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'field_dst'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'datasource' => ( is => 'ro', isa => 'Str', required => 0 );
has 'valid_regex'   => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'invalid_regex' => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_params',
);

sub _build_params {
    my $self = shift;
    my $p = {};
    $p->{field_src}   = $self->field_src;
    $p->{field_dst}   = $self->field_dst;
    $p->{attributes}  = $self->attributes;
    $p->{datasource}  = $self->datasource;
    $p->{method}      = $self->method // 'split_field';
    return $p;
}

sub BUILDARGS {
    my $class = shift;
    my $p     = shift;

    # Check the 'attributes' attribute.  If the default is not used
    # REPLACENULL is not set, and the exception is thrown.  Solution:
    # always set one of the below attribs togheter with COPY or MOVE.
    my $a = $p->{attributes};
    hurl recipe =>
        "For the 'copy' step, one of the attributes: REPLACE, REPLACENULL, APPEND or APPENDSRC is required!"
        unless ( $a->{REPLACE} or $a->{REPLACENULL} or $a->{APPEND}
        or $a->{APPENDSRC} );
    hurl recipe =>
        "Attributes: REPLACE, REPLACENULL, APPEND and APPENDSRC are mutually exclusive!"
        unless ( $a->{REPLACE} xor $a->{REPLACENULL} xor $a->{APPEND}
        xor $a->{APPENDSRC} );

    return $p;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform::Row::Copy - Row transformation step - copy

=head1 Synopsis

   my $steps = App::Transfer::Recipe::Transform::Row::Copy->new(
      $self->recipe_data->{step},
   );

Where the C<step> type is C<copy>.

=head1 Description

An object representing a C<row> recipe transformations C<step> section
with the type attribute set to C<copy>.

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

=head3 C<datasource>

XXX Clarify.

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
