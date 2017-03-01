package App::Transfer::Writer::csv;

# ABSTRACT: Writer for CSV files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File Path);
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use Text::CSV;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

extends 'App::Transfer::Writer';
with    'App::Transfer::Role::Utils';

has 'output_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    lazy     => 1,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        return $self->options->file_path;
    },
);

has 'csv' => (
    is       => 'ro',
    isa      => 'Text::CSV',
    lazy     => 1,
    init_arg => undef,
    default => sub {
        return Text::CSV->new(
            {   sep_char       => ';',
                always_quote   => 0,
                binary         => 1,
                eol            => "\n",
            }
        ) || die "Cannot create CSV: " . Text::CSV->error_diag();
    },
);

has 'csv_fh' => (
    is       => 'ro',
    isa      => 'FileHandle',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $file = $self->output_file;
        my $fh   = $file->openw_utf8( { locked => 1 } )
            or hurl io => __x(
                "Cannot open '{file}': {error}",
                file  => $file,
                error => $!
            );
        return $fh;
    },
);

has '_headers' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    traits   => ['Array'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_headers',
    handles  => {
        get_header  => 'get',
        all_headers => 'elements',
    },
);

sub _build_headers {
    my $self = shift;

    # Header is the first row
    my @headers = ();
    foreach my $name ( $self->recipe->tables->all_table_names ) {
        my $skip_rows = $self->recipe->tables->get_table($name)->skiprows;
        my $tempfield = $self->recipe->tables->get_table($name)->tempfield;
        my $row_count = 0;
        my $columns = $self->recipe->tables->get_table($name)->columns;
        my @cols    = $self->sort_hash_by_pos($columns);
        push @headers, {
            table  => $name,
            row    => $row_count,
            header => \@cols,
            skip   => $skip_rows,
            temp   => $tempfield,
        };
    }
    return \@headers;
}

sub insert_header {
    my $self   = shift;
    my $csv_o  = $self->csv;
    my $out_fh = $self->csv_fh;
    my $header = $self->get_header(0)->{header};
    $csv_o->column_names($header);
    my $status = $csv_o->print( $out_fh, $header );
    $self->emit_error if !$status;
    return;
}

sub insert {
    my ( $self, $table, $row ) = @_;
    my $csv_o  = $self->csv;
    my $out_fh = $self->csv_fh;
    my $status = $csv_o->print_hr( $out_fh, $row );
    if (!$status) {
        $self->emit_error;
        $self->inc_skipped;
    }
    else {
        $self->inc_inserted;
    }
    return;
}

sub finish {
    my $self = shift;
    my $file = $self->csv_fh;
    $file->close or hurl io => __x(
        "Cannot close '{file}': {error}",
        file  => $file,
        error => $!
    );
    return;
}

sub emit_error {
    my ($self, $csv_o) = @_;
    my $error = $csv_o->error_input();
    hurl io => __x(
        "CSV error: {error}",
        error => $error,
    );
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Writer::csv - Writer for CSV files

=head1 Synopsis

  my $writer = App::Transfer::Writer->load( { writer => 'csv' } );

=head1 Description

App::Transfer::Writer::csv reads a CSV file and builds a AoH data
structure for the entire contents.

The input file must be in UTF8 format and the output is also UTF8 to
be inserted in the database.

TODO: Consider Text::CSV::Encoded.  Tests failed for v0.22 with
"Wide character in subroutine entry...".

=head1 Interface

=head2 Attributes

=head3 C<output_file>

A L<Path::Tiny::File> object representing the CSV output file.

=head3 C<csv>

A L<Text::CSV> object.

=head3 C<_headers>

An array reference holding info about the table in the file.  The
data-structure contains the table, row, header and skip attributes.

=head2 Instance Methods

=head3 C<insert_header>

Insert the header row in the CSV.

=head3 C<insert>

Insert a row of data in the CSV.

=head3 C<finish>

Close the output file.

=head3 C<emit_error>

Throw an exception if the row of data has problems.

=cut
