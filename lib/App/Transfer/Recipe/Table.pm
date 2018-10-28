package App::Transfer::Recipe::Table;

# ABSTRACT: Recipe section: table

use 5.010001;
use Moose;
use Data::Leaf::Walker;
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

has 'logfield' => ( is => 'ro', isa => 'Str' );

has 'rectangle' => (
    is     => 'ro',
    isa    => 'CoordsArrayFromStr',
    coerce => 1,
);

has 'allowemptyrows' => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { 1 },
);

has 'orderby' => (
    is     => 'ro',
    isa    => 'Str|ArrayRef|HashRef',
    coerce => 0,
);

has '_filter' => (
    is       => 'ro',
    init_arg => 'filter',
    isa      => 'Maybe[ArrayRef|HashRef]',
);

has 'filter' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef|HashRef]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_filter',
);

sub _build_filter {
    my $self = shift;
    my $data = $self->_filter;
    return if !ref $data;
    my $walk = Data::Leaf::Walker->new($data);
    while ( my ( $k, $v ) = $walk->each ) {
        $walk->store( $k, undef ) if $v eq 'NOT_NULL';
    }
    return $data;
}

has 'columns' => (
    is       => 'ro',
    isa      => 'HashRef|ArrayRef',
);

has '_src_header' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    default  => sub { [] },
    init_arg => 'src_header',
    handles  => {
        src_header_raw => 'elements',
        src_header_def => 'grep',
    },
);

sub src_header {
    my $self = shift;
    my @header = $self->src_header_def( sub { $_ } );
    return \@header;
}

has 'dst_header' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->src_header;
    },
);

has 'header_map' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $h_map = {};
        foreach my $field ( @{ $self->src_header } ) {
            $h_map->{$field} = $field;
        }
        return $h_map;
    },
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

Example from siruta.C<xls> for the siruta table:

    rectangle = A7,C21

New feature in v0.44: for the C<xls> reader, the bottom right corner can
be specified as C<END>. This means that the C<maxrow> ans C<maxcoll>
attributes from the L<Spreadsheet::Read> module are used to determine
the actual value of the attribute.

    rectangle = A7,END

See C<allowemptyrows> for more options.

=head3 C<allowemptyrows>

Specific for the C<xls> reader.

Stop reading data from the C<xls> source file if more than
C<allowemptyrows> empty adjacent rows are encountered.

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
