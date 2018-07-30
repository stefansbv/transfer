package App::Transfer::Recipe::Table;

# ABSTRACT: Recipe section: table

use 5.010001;
use Moose;
use Data::Leaf::Walker;
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

has 'logfield' => ( is => 'ro', isa => 'Str' );

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'rectangle' => (
    is     => 'ro',
    isa    => 'CoordsArrayFromStr',
    coerce => 1,
);

has 'orderby' => (
    is     => 'ro',
    isa    => 'Str|ArrayRef|HashRef',
    coerce => 0,
);

has '_filter' => (
    is       => 'ro',
    init_arg => 'filter',
    isa      => 'ArrayRef|HashRef',
    default  => sub { {} },
);

has 'filter' => (
    is       => 'ro',
    isa      => 'ArrayRef|HashRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_filter',
);

sub _build_filter {
    my $self = shift;
    my $data = $self->_filter;
    my $walk = Data::Leaf::Walker->new($data);
    while ( my ( $k, $v ) = $walk->each ) {
        $walk->store( $k, undef ) if $v eq 'NOT_NULL';
    }
    return $data;
}

has 'columns' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);

has 'src_header' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has 'dst_header' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has 'header_map' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'tempfield' => (
    is     => 'ro',
    isa    => 'ArrayRefFromStr',
    coerce => 1,
);

has 'plugins' => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => { get_plugin => 'get' },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Tables::Table - Recipe section: table

=head1 Synopsis

  my $tables = App::Transfer::Recipe::Tables::Table->new(
      $self->table->{$name},
  );

=head1 Description

An object representing the C<header> subsection of the C<tables>
section of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Tables::HeadrMap>
object.

  my $tables = App::Transfer::Recipe::Tables::Table->new(
      $self->table->{$name},
  );

=head2 Attributes

=head3 C<description> !REMOVED!

A description of the table.  Not used, yet.

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

=head3 C<rectangle>

Data rectangle defined by the label of the top left and bottom right
cell.

Example from siruta.xls for the siruta table:

    rectangle = A7,C21

=head3 C<skiprows>  !REMOVED!

The number of rows to skip between the header and the table data.
Used for the C<xls> reader, when there are empty or unwanted rows
after the header or there is a sub-header.

=head3 C<orderby>

An attribute holding the C<order> argument for the L<SQL::Abstract>
C<select> method.  The argument can be a C<Scalar>, a C<HashRef> or an
<ArrayRef>.

=head3 C<header>

A hash/array reference representing the C<header> subsection of a table
recipe configuration.

=over

=item B<array>

The C<header> table subsection lists the header columns of the input
(source).

=item B<hash>

The C<header> table subsection maps the header columns of the input
(source) with the header columns of the output (destination).

=back

=head3 C<columns>

A hash reference representing the C<columns> subsection of a table
recipe configuration.  It is optional and is only for recipes with
file type destinations.

For example:

    <table table_name>
      <columns>
        <col_name>
          pos             = 1
          name            = col_name
          type            = integer
          length          = 2
          prec            =
          scale           =
        </col_name>
        ...
      </columns>
      <header>
      ...
    </table>

=cut
