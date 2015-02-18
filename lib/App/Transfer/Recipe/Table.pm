package App::Transfer::Recipe::Table;

# ABSTRACT: Recipe section: tables

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use App::Transfer::Recipe::Table::HeaderMap;

has 'worksheet' => ( is => 'ro', isa => 'Str' );
has 'lastrow'   => ( is => 'ro', isa => 'Maybe[Int]' );
has 'table'     => ( is => 'ro', isa => 'HashRef', required => 1 );

has '_table_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    traits   => ['Array'],
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my @tables = keys %{ $self->table };
        return \@tables;
    },
    handles  => {
        get_table_name  => 'get',
        all_table_names => 'elements',
        find_table_name => 'first',
    },
);

has '_tables' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my %tables;
        foreach my $name ( keys %{ $self->table } ) {
            $tables{$name} = App::Transfer::Recipe::Table::HeaderMap->new(
                $self->table->{$name}
            );
        }
        return \%tables;
    },
    handles  => {
        get_table => 'get',
    },
);

sub has_table {
    my ($self, $name) = @_;
    die "the name parameter is required!" unless defined $name;
    return $self->find_table_name( sub { /$name/ } );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Table - Recipe section: tables

=head1 Synopsis

  my $tables = App::Transfer::Recipe::Table->new(
      $self->recipe_data->{tables},
  );

=head1 Description

An object representing the C<tables> section of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Table> object.

  my $tables = App::Transfer::Recipe::Table->new(
      $self->recipe_data->{tables},
  );

=head2 Attributes

=head3 C<worksheet>

The name of the worksheet.  Used only for the C<excel> reader.

=head3 C<lastrow>

Returns the C<lastrow> attribute from the C<tables> section of the
recipe.

=head3 C<table>

Returns an object instance representing the C<tables> section of the
recipe.

=head3 C<_table_list>

An array reference attribute holding the list of the tables configured
for the recipe.

=head3 C<_tables>

A hash reference holding the table names as keys and the corresponding
object instance of L<App::Transfer::Recipe::Table::HeaderMap> as
values.

=head2 Instance Methods

=head2 C<has_table>

  $tables->has_table($name);

Returns true if the table configuration exists for C<$name>.

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
