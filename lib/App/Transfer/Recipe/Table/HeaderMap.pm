package App::Transfer::Recipe::Table::HeaderMap;

# ABSTRACT: Recipe section: tables/table/headermap

use 5.010001;
use Moose;
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

has 'description' => ( is => 'ro', isa => 'Str' );
has 'logfield'    => ( is => 'ro', isa => 'Str' );

has 'skiprows' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 0 },
);

has 'orderby' => (
    is     => 'ro',
    isa    => 'ArrayRefFromStr',
    coerce => 1,
);

has 'headermap' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { {} },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Table::HeaderMap - Recipe section: tables/table/headermap

=head1 Synopsis

  my $tables = App::Transfer::Recipe::Table::HeaderMap->new(
      $self->table->{$name},
  );

=head1 Description

An object representing the C<headermap> subsection of the C<tables>
section of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Table::HeadrMap>
object.

  my $tables = App::Transfer::Recipe::Table::HeaderMap->new(
      $self->table->{$name},
  );

=head2 Attributes

=head3 C<description>

A description of the table.  Not used, yet.

=head3 C<skiprows>

The number of rows to skip between the header and the table data.
Used for the C<excel> reader, when there are empty rows after the
header or a sub-header

=head3 C<logfield>

The name of the field (column) used for logging info.  Should be set to
a column name from the destination table with unique values that makes
it easy to spot the rows with problems.

Example log record:

               record No
               v
    [3094] [id:6] lookup: multiple values for...
            ^
            logfield name

=head3 C<headermap>

A hash reference representing the C<headermap> subsection of a table
recipe configuration.

The C<headermap> subsection maps the header columns of the input
(source) with the header columns of the output (destination).

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
