package App::Transfer::Reader::spreadsheet;

# ABSTRACT: Reader for spreadsheet files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(first any all);
use List::Compare;
use Spreadsheet::Read;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

use Data::Dump;

extends 'App::Transfer::Reader';

has 'input_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    lazy     => 1,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        return $self->options->file;
    },
);

has 'worksheet' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->tables->worksheet;
    },
);

has 'workbook' => (
    is      => 'ro',
    isa     => 'Spreadsheet::Read',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Spreadsheet::Read->new( $self->input_file->stringify );
    },
);

has 'sheet' => (
    is      => 'ro',
    isa     => 'Spreadsheet::Read::Sheet',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->workbook->sheet( $self->worksheet );
    },
);

has '_header_prev' => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        set_header     => 'set',
        get_header     => 'get',
        has_no_headers => 'is_empty',
    },
);

has '_tables_meta' => (
    isa      => 'HashRef[HashRef]',
    traits   => ['Hash'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_tables_meta',
    handles  => {
        all_meta       => 'elements',
        get_table_meta => 'get',
        meta_pairs     => 'kv',
    },
);

sub _build_tables_meta {
    my $self = shift;
    my $meta = {};
    foreach my $name ( $self->recipe->tables->all_table_names ) {
        my $headermap = $self->recipe->tables->get_table($name)->headermap;
        use Data::Printer; p $headermap;
        my $src_cols  = [ keys %{$headermap} ];
        my $dst_cols  = [ values %{$headermap} ];
        my $src_count = scalar @{$src_cols};
        my $dst_count = scalar @{$dst_cols};
        $meta->{$name} = {
            src_cols  => $src_cols,
            dst_cols  => $dst_cols,
            headermap => $headermap,
            rectangle => $self->recipe->tables->get_table($name)->rectangle,
        };
    }
    return $meta;
}

sub _read_rectangle {
    my ($self, $top_cell, $bot_cell) = @_;

    my ($col_min, $row_min) = $self->sheet->cell2cr($top_cell);
    my ($col_max, $row_max) = $self->sheet->cell2cr($bot_cell);

    say "row_min = $row_min  row_max = $row_max"; # if $self->debug;
    say "col_min = $col_min  col_max = $col_max"; # if $self->debug;

    my $header = $self->get_table_meta('siruta')->{dst_cols};
    use Data::Dump; dd $header;

    my @aoh = ();
    for my $row_cnt ( $row_min .. $row_max ) {
        my @row = $self->sheet->row($row_cnt);
        my $rec = {};
        foreach my $col_cnt ( $col_min .. $col_max ) {
            # say "col count = ", $col_cnt;
            my $field = $header->[ ($col_cnt - 1) ];
            my $value = $row[$col_cnt];
            say "$field = $value";
            # $rec->{$field} = $value;
            # use Data::Dump; dd $rec;
        }
        # push @aoh, $rec;
        # $self->inc_count;
    }
    return \@aoh;
}

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self         = shift;
    my $recipe_table = $self->recipe->tables->get_table('siruta');
    my ( $top, $bot ) = @{ $recipe_table->rectangle };
    say "reading rectangle [$top, $bot]";
    return $self->_read_rectangle( $top, $bot );
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

# sub has_table {
#     my ($self, $name) = @_;
#     die "the name parameter is required!" unless defined $name;
#     return $self->recipe->tables->has_table($name);
# }

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader::xls - Reader for MSExcel files

=head1 Synopsis

  my $reader = App::Transfer::Reader->load( { reader => 'xls' } );

=head1 Description

App::Transfer::Reader::xls reads an MSExcel file worksheet and
builds a AoH data structure for the entire contents.

=head1 Interface

=head2 Attributes

=head3 C<input_file>

A L<Path::Tiny::File> object representing the xls input file.

=head3 C<dst_table>

The name of the destination table.

=head3 C<worksheet>

The name of the xls worksheet to read from.  It is a C<tables>
section attribute in the recipe.

=head3 C<maxrow>

An integer value with the maximum row number.

=head3 C<lastrow>

The last row number (counting from 1) with data on the xls
worksheet.  It is a C<tables> section attribute in the recipe.

=head3 C<lastcol>

The last col number (counting from 1) with data on the xls
worksheet.  It is a C<tables> section attribute in the recipe.

=head3 C<_headers>

An array reference holding info about each table in the worksheet.

The data-structure is built by iterating over the contents of the
spreadsheet and searching for the header columns defined in the
L<headermap> section of the recipe.  When a header is found, the row
is and some other info is recorded.

=head3 C<_record_set>

=head3 C<_contents>

An array reference holding the contents of the spreadsheet.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the xls file.

=head3 C<workbook>

A L<Spreadsheet::Read> object.

=head2 Instance Methods

=head3 C<has_table>

Return true if the table $name is defined in the recipe (actually
returns the name of the table or undef).

=head3 C<get_data>

Return an array reference of hashes, where the hash keys are the names
of the columns and the values are the values read from the table
columns. (XXX reformulate).

=cut
