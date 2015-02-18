package App::Transfer::Recipe::Transform;

# ABSTRACT: Recipe section: transform

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use Locale::TextDomain 1.20 qw(App-Transfer);
use namespace::autoclean;

use App::Transfer::Recipe::Transform::Col::Step;
use App::Transfer::Recipe::Transform::Row::Step;

subtype 'ArrayRefColStep',
    as 'ArrayRef[App::Transfer::Recipe::Transform::Col::Step]';

subtype 'ArrayRefRowStep',
    as 'ArrayRef[App::Transfer::Recipe::Transform::Row::Step]';

coerce 'ArrayRefColStep'
    => from 'HashRef[ArrayRef]' => via {
        [ map { App::Transfer::Recipe::Transform::Col::Step->new($_) }
          @{ $_->{step} } ] }
    => from 'HashRef[HashRef]' => via {
        [ App::Transfer::Recipe::Transform::Col::Step->new( $_->{step} ) ];
    };

coerce 'ArrayRefRowStep'
    => from 'HashRef[ArrayRef]' => via {
        [ map { App::Transfer::Recipe::Transform::Row::Step->new($_) }
          @{ $_->{step} } ] }
    => from 'HashRef[HashRef]' => via {
        [ App::Transfer::Recipe::Transform::Row::Step->new( $_->{step} ) ];
    };

has 'column' => (
    is     => 'ro',
    isa    => 'ArrayRefColStep',
    coerce => 1,
);

has 'row' => (
    is     => 'ro',
    isa    => 'ArrayRefRowStep',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform - Recipe section object: transform

=head1 Synopsis

  my $transform = App::Transfer::Recipe::Transform->new(
      $self->recipe_data->{transform},
  );

=head1 Description

An object representing the C<transform> section of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Transform>
object.

  my $transform = App::Transfer::Recipe::Transform->new(
      $self->recipe_data->{transform},
  );

=head2 Attributes

=head3 C<row>

Returns an object instance representing a C<row> type transformation.
This kind of transformation can read from multiple source fields
(columns) and/or write to multiple destination fields.

=head3 C<column>

Returns an object instance representing a C<column> type
transformation.  This kind of transformation can read from a single
source field (column) and write to a single destination field.

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
