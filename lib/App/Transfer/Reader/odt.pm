package App::Transfer::Reader::odt;

# ABSTRACT: Reader for ODT files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(first any);
use List::Compare;
use ODF::lpOD;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

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

has '_headermap' => (
    isa      => 'ArrayRef[HashRef]',
    traits   => ['Array'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_headermap',
    handles  => {
        get_header    => 'get',
        all_headermap => 'elements',
    },
);

sub _build_headermap {
    my $self = shift;

    # Header is the first row
    my @metadata = ();
    foreach my $name ( $self->recipe->tables->all_table_names ) {
        my $headermap = $self->recipe->tables->get_table($name)->headermap;
        my $skip_rows = $self->recipe->tables->get_table($name)->skiprows;
        my $tempfield = $self->recipe->tables->get_table($name)->tempfield;
        my $row_count = 0;
        push @metadata, {
            table     => $name,
            row       => $row_count,
            headermap => $headermap,
            skip      => $skip_rows,
            tempfield => $tempfield,
        };
    }
    return \@metadata;
}

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;
    my $doc  = $self->doc;
    my $headermap = $self->get_header(0)->{headermap};
    my $tempfield = $self->get_header(0)->{temp};
    my $table = $doc->get_body->get_table;
    my ( $h, $w ) = $table->get_size;
    my $row = $table->get_row(0);

    # Get the field names from the header, compress the text, remove
    # some chars like in the header-map
    # NOTE: get_row_header() get_header() and get_cell_values() does not work
    my @cols;
    for (my $j = 0; $j < $w; $j++) {
        my $cell = $row->get_cell($j) or last CELL;
        my $text = $cell->get_text;
        $text = lc $self->common_RON->translit($text);
        ( my $col = $text ) =~ s{[-./\s]}{}gi if defined $text;
        push @cols, $col;
    }

    # Add the temporary fields to the record
    foreach my $field ( @{$tempfield} ) {
        $headermap->{$field} = $field;
    }

    # Validate field list
    my @not_found = ();
    foreach my $col ( keys % {$headermap} ) {
        unless ( any { $col eq $_ } @cols ) {
            push @not_found, $col;
        }
    }
    hurl field_info => __x(
        'Header map <--> CSV file header inconsistency. Some columns where not found :"{list}"',
        list  => join( ', ', @not_found ),
    ) if scalar @not_found;

    my @records;

  ROW:
    for ( my $i = 1; $i < $h; $i++ ) {
        my $row = $table->get_row($i) or last ROW;
        my $record = {};
      CELL:
        for ( my $j = 0; $j < $w; $j++ ) {
            my $col  = $cols[$j];
            my $cell = $row->get_cell($j) or last CELL;
            my $text = $cell->get_text;
            if ( my $field = $headermap->{$col} ) {
                $record->{$field} = $text;
            }
        }
        push @records, $record
            if any { defined($_) } values %{$record};
    }
    return \@records;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

has 'doc' => (
    is       => 'ro',
    isa      => 'ODF::lpOD::Document',
    lazy     => 1,
    init_arg => undef,
    default => sub {
        my $self = shift;
        my $doc  = odf_document->get( $self->input_file->stringify );

        # die "Error:", $parser->error(), ".\n" if !defined $doc;
        return $doc;
    },
);

sub get_data {
    my $self = shift;
    my $iter = $self->contents_iter;
    my @records;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        push @records, $row if any { defined($_) } values %{$row};
    }
    $self->record_count(scalar @records);
    return \@records;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader::odt - Reader for files in Open Document Format.

=head1 Synopsis

  my $reader = App::Transfer::Reader->load( { reader => 'odt' } );

=head1 Description

App::Transfer::Reader::odt reads an C<odt> Open Document Format file
and builds a AoH data structure for the first table.

TODO: Add support for more than one table.

=head1 Interface

=head2 Attributes

=head3 C<input_file>

A L<Path::Tiny::File> object representing the odt input file.

=head3 C<dst_table>

The name of the destination table.

=head3 C<_headermap>

An array reference holding info about each table. TODO!!!

The data-structure is built by iterating over the contents of the
spreadsheet and searching for the header columns defined in the
L<headermap> section of the recipe.  When a header is found, the row
and some other info is recorded.

=head3 C<_record_set>

=head3 C<_contents>

An array reference holding the contents of the tables.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the odt file.

=head3 C<doc>

A L<...> object.

=head2 Instance Methods

=head3 C<get_data>

Return an array reference of hashes, where the hash keys are the names
of the columns and the values are the values read from the table
columns. (XXX reformulate).

=cut
