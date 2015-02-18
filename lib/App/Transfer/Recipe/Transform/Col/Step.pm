package App::Transfer::Recipe::Transform::Col::Step;

# ABSTRACT: Column transformation step

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use App::Transfer::Recipe::Transform::Types;

has 'field' => ( is => 'ro', isa => 'Str' );

has 'method' => (
    is     => 'ro',
    isa    => 'ArrayRefFromStr',
    coerce => 1
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform::Col::Step - Column transformation step

=head1 Synopsis

   my $steps = App::Transfer::Recipe::Transform::Col::Step->new(
      $self->recipe_data->{step},
   );

=head1 Description

An object representing a C<step> section of the type C<column> recipe
transformations.

=head1 Interface

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Col::Step> object.

   my $steps = App::Transfer::Recipe::Transform::Col::Step->new(
      $self->recipe_data->{step},
   );

=head2 Attributes

=head3 C<field>

A string attribute representing the name of the field (column).

=head3 C<method>

An array reference with the name(s) of the plugin method to be called
for the transformation.  If there is more than one method, all methods
will be called in order and the result of the first is passed to the
next, and so on.

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
