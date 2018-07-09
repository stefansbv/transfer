package App::Transfer::Recipe::Types;

# ABSTRACT: Recipe types

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'Natural', as 'Int', where { $_ > 0 };

subtype 'NaturalLessThanN', as 'Natural', where { $_ <= 2 },
    message { "The number ($_) is not <= 1!" };

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
        [ map {
            App::Transfer::Recipe::Transform::Row::Factory->create(
                $_->{type}, $_ ) } @{ $_->{step} } ] }
    => from 'HashRef[HashRef]' => via {
        [ App::Transfer::Recipe::Transform::Row::Factory->create(
            $_->{step}{type}, $_->{step} ) ];
    };

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Types - Recipe attribute data types

=head1 Synopsis

  use App::Transfer::Recipe::Types;

=head1 Description

This module defines data types used in Transfer::Recipe object
attributes.  Supported types are:

=over

=item C<Natural>

A real integer value.

=item C<NaturalLessThanN>

A real integer value lees than C<N>.  Where C<N> is the current recipe
syntax version.

=back

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
