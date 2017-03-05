package App::Transfer::Reader::xls;

# ABSTRACT: Reader for MSExcel files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(first any);
use List::Compare;
use Spreadsheet::ParseExcel;
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

has 'dst_table' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->destination->table;
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

has 'maxrow' => (
    is       => 'rw',
    isa      => 'Int',
    init_arg => undef,
    default  => 0,
);

has 'lastrow' => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->tables->lastrow;
    },
);

has '_headers' => (
    isa      => 'ArrayRef[HashRef]',
    traits   => ['Array'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_headers',
    handles  => {
        all_headers => 'elements',
    },
);

sub _build_headers {
    my $self = shift;

    my @headers;
    my $row_count = 0;
    my $iter      = $self->contents_iter;
    my $found_tables    = 0;
    my $expected_tables = $self->recipe->tables->count_tables; # XXX stop when all found
    say "expected_tables = $expected_tables";
    while ( $iter->has_next ) {
        my $row  = $iter->next;

        # Compress the text, remove some chars like in the header-map
        my $cols = [];
        foreach my $col ( @{$row} ) {
            my $text = $col;
            ( $text = $col ) =~ s{[-./\s]}{}gi if defined $col;
            push @{$cols}, $text;
        }

        # push @records, $record
        #     if any { defined($_) } values %{$record};

        say "cols:";
        dd $cols;

        # Search for headers
      HEADER:
        foreach my $name ( $self->recipe->tables->all_table_names ) {
            my $headermap = $self->recipe->tables->get_table($name)->headermap;
            my $skip_rows = $self->recipe->tables->get_table($name)->skiprows;
            my $head_cols = [ keys %{$headermap} ];

            # say "headermap";
            # dd $headermap;
            # say "header_cols";
            # dd $head_cols;

            my $lc = List::Compare->new( $head_cols, $cols );
            next HEADER unless $lc->get_intersection;

            say "Header at row ", ($row_count + 1); # if $self->verbose;
            my $record = [];
            foreach my $col ( @{$cols} ) {
                push @{$record}, $headermap->{$col} if defined $col;
            }

            # Check header record
            if ( @{$record} ) {
                $self->_debug_config_map( $name, $record )
                    if any { !defined($_) } @{$record};
                push @headers, {
                    table  => $name,
                    row    => $row_count,
                    header => $record,
                    skip   => $skip_rows,
                };
            }
            $found_tables++;
        }
        $row_count++;
    }

    $self->maxrow($row_count);    # store row count
    return \@headers;
}

has '_record_set' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_record_set',
    handles  => {
        get_recordset     => 'get',
        has_no_recordsets => 'is_empty',
        num_recordsets    => 'count',
    },
);

sub _build_record_set {
    my $self = shift;

    # A record set has a header and a data range
    # Data ranges are between the header rows or after the last
    # header till the end of the table
    my %range;
    my @header_rows = map { $_->{row} } $self->all_headers;
    foreach my $header ( $self->all_headers ) {
        my $table = $header->{table};
        my $hrow  = $header->{row};
        my $skip  = $header->{skip} // 0;

        my $min = $hrow + 1 + $skip;
        die "Bad range (min) for '$table'" unless defined $min;

        my $max = first { $_ > $min } @header_rows;
        $max-- if defined $max;    # 1 less than the next header

        die "Bad range for '$table'" if defined $max and $min >= $max;

        $range{$table}{header} = $header->{header};
        $range{$table}{min}    = $min;
        $range{$table}{max}    = $max;
    }

    return \%range;
}

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;

    my $worksheet;
    if ( $self->worksheet ) {
        $worksheet = $self->workbook->worksheet( $self->worksheet );
        hurl xls =>
            __x( 'Worksheet "{worksheet}" not found in the XSL file',
                 worksheet => $self->worksheet )
            unless defined $worksheet;
    }
    else {
        $worksheet = $self->workbook->worksheet(0); # default 0
    }

    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    say "row_min = $row_min   row_max = $row_max";
    say "col_min = $col_min   col_max = $col_max";

    $row_max = $self->lastrow if defined $self->lastrow;

    my @aoa = ();
    for my $row ( 0 .. $row_max ) {
        my @cols = ();
        for my $col ( $col_min .. $col_max ) {
            my $cell  = $worksheet->get_cell( $row, $col );
            next unless $cell;
            my $value = $cell->value();
            push @cols, $value ? $value : undef; # for NULL in DB
        }
        push @aoa, [@cols];
    }

    return \@aoa;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

has 'workbook' => (
    is       => 'ro',
    isa      => 'Spreadsheet::ParseExcel::Workbook',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self     = shift;
        my $parser   = Spreadsheet::ParseExcel->new;
        my $workbook = $parser->parse( $self->input_file->stringify );
        die "Error:", $parser->error(), ".\n" if !defined $workbook;
        return $workbook;
    },
);

sub _debug_config_map {
    my ($self, $name, $record) = @_;
    my $header = $self->recipe->tables->get_table($name)->headermap;

    my @header = values %{$header};
    my $lc = List::Compare->new( \@header, $record );
    my @fields = $lc->get_unique;

    my %revers = reverse %{$header};
    my @errors = map { $revers{$_} } @fields;

    say "\nCheck header text for:";
    say "  * '$_'" for @errors;

    die "Configuration error(s) detected, aborting.\n";
}

sub has_table {
    my ($self, $name) = @_;
    die "the name parameter is required!" unless defined $name;
    return $self->recipe->tables->has_table($name);
}

sub get_data {
    my $self = shift;

    my $table    = $self->dst_table;
    die "Error: no table named '$table'!" unless $self->has_table($table);
    die "No record set for '$table'" if $self->has_no_recordsets;
    my $iter     = $self->contents_iter;
    my $data_set = $self->get_recordset($table);
    my $header   = $data_set->{header};
    my $min      = $data_set->{min};
    my $max      = $data_set->{max} // $self->maxrow;

    my $row_count = 0;
    my @records;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        if ( $row_count >= $min && $row_count <= $max ) {
            my $record = {};
            for ( my $idx = 0; $idx <= $#{$header}; $idx++ ) {
                my $cell_value = $row->[$idx];
                $record->{ $header->[$idx] } = $cell_value;
            }

            # Only records with at least one defined value
            push @records, $record
                if any { defined($_) } values %{$record};
        }
        $row_count++;
    }
    $self->record_count($row_count);
    return \@records;
}

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

The last row number (counting from 0) with data on the xls
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

A L<Spreadsheet::ParseExcel::Workbook> object.

=head2 Instance Methods

=head3 C<_debug_config_map>

Print a list of the headers without a valid mapping.

=head3 C<has_table>

Return true if the table $name is defined in the recipe (actually
returns the name of the table or undef).

=head3 C<get_data>

Return an array reference of hashes, where the hash keys are the names
of the columns and the values are the values read from the table
columns. (XXX reformulate).

=cut
