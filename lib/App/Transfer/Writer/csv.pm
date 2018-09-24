package App::Transfer::Writer::csv;

# ABSTRACT: Writer for CSV files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File Path);
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use Text::CSV;
use Path::Tiny;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

use Data::Dump qw/dump/;

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
        my $file = $self->writer_options->file;
        $file .= '.csv' unless $file =~ m{\.csv}i;
        return $file;
    },
);

has 'output_path' => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->writer_options->path || '.';
    },
);

has 'output' => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return path $self->output_path, $self->output_file;
    },
);

has 'header' => (
    is       => 'ro',
    isa      => 'HashRef|ArrayRef',
    required => 1,
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
        my $file = $self->output;
        my $fh   = $file->openw_utf8( { locked => 1 } )
            or hurl io => __x(
                "Cannot open '{file}': {error}",
                file  => $file,
                error => $!
            );
        return $fh;
    },
);

sub insert_header {
    my ($self, $header_fields) = @_;
    my $csv_o  = $self->csv;
    my $out_fh = $self->csv_fh;
    my @field_names;
    if ( ref $header_fields eq 'ARRAY' ) {
        @field_names = @{$header_fields};
    }
    else {
        my $header = $self->header;
        @field_names
            = ( ref $header eq 'HASH' )
            ? keys( %{$header} )
            : @{$header};
    }
    hurl csv => __(
        "Empty header for CSV writer"
    ) if scalar @field_names == 0;
    $csv_o->column_names(\@field_names);
    say "# writer CSV header: \n# ", join ', ', @field_names if $self->debug;
    my $status = $csv_o->print( $out_fh, \@field_names );
    $self->emit_error($csv_o) if !$status;
    return;
}

sub insert {
    my ( $self, $table, $row ) = @_;
    my $csv_o  = $self->csv;
    my $out_fh = $self->csv_fh;
    my $status;
    if ( any { $_ } values %{$row} ) {
        $status = $csv_o->print_hr( $out_fh, $row );
    }
    else {
        $self->inc_skipped;
    }
    if ($status) {
        $self->inc_inserted;
    }
    else {
        $self->emit_error($csv_o);
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
