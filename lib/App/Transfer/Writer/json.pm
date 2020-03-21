package App::Transfer::Writer::json;

# ABSTRACT: Writer for JSON files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File Path);
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use JSON;
use Path::Tiny;
use App::Transfer::X qw(hurl);
use Data::Dump;
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
        my $file = $self->writer_options->file;
        $file .= '.json' unless $file =~ m{\.json}i;
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

has '_record' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    handles => {
        all_records    => 'elements',
        add_record     => 'push',
        get_record     => 'get',
        count_records  => 'count',
        has_no_records => 'is_empty',
    },
);

has 'json' => (
    is       => 'ro',
    isa      => 'JSON',
    lazy     => 1,
    init_arg => undef,
    default => sub {
        return JSON->new->allow_nonref;
    },
);

has 'json_fh' => (
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

    # do nothing
    return;
}

sub insert {
    my ( $self, $row, $table ) = @_;
    if ( $self->debug ) {
        say "# record (before insert):";
        ddx $row;
    }
    if ( any { $_ } values %{$row} ) {
        $self->add_record($row);
        $self->inc_inserted;
    }
    else {
        $self->inc_skipped;
    }
    return;
}

sub finish {
    my $self = shift;
    my $file = $self->json_fh;
    my @records = $self->all_records;
    my $pp = $self->json->pretty->encode(@records); # pretty-printing
    print {$file} $pp;
    $file->close or hurl io => __x(
        "Cannot close '{file}': {error}",
        file  => $file,
        error => $!
    );
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

App::Transfer::Writer::csv - Writer for CSV files

=head1 SYNOPSIS

  my $writer = App::Transfer::Writer->load( { writer => 'csv' } );

=head1 DESCRIPTION

App::Transfer::Writer::csv reads a CSV file and builds a AoH data
structure for the entire contents.

The input file must be in UTF8 format and the output is also UTF8 to
be inserted in the database.

TODO: Consider Text::CSV::Encoded.  Tests failed for v0.22 with
"Wide character in subroutine entry...".

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 C<output_file>

A L<Path::Tiny::File> object representing the CSV output file.

=head3 C<csv>

A L<Text::CSV> object.

=head2 INSTANCE METHODS

=head3 C<insert_header>

Insert the header row in the CSV.

=head3 C<insert>

Insert a row of data in the CSV.

=head3 C<finish>

Close the output file.

=head3 C<emit_error>

Throw an exception if the row of data has problems.

=cut
