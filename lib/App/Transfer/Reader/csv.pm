package App::Transfer::Reader::csv;

# ABSTRACT: Reader for Excel files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw{any};
use Text::CSV;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

extends 'App::Transfer::Reader';

has 'input' => (
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

has 'recipe' => (
    is       => 'ro',
    isa      => 'App::Transfer::Recipe',
    required => 1,
);

has 'options' => (
    is       => 'ro',
    isa      => 'App::Transfer::Options',
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
                blank_is_undef => 1,
            }
        ) or die "Cannot use CSV: " . Text::CSV->error_diag();
    },
);

has '_headers' => (
    isa      => 'ArrayRef',
    traits   => ['Array'],
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;

        # Header is the first row
        my @headers = ();
        foreach my $name ( $self->recipe->tables->all_table_names ) {
            my $header    = $self->recipe->tables->get_table($name)->headermap;
            my $skip_rows = $self->recipe->tables->get_table($name)->skiprows;
            my $row_count = 0;
            push @headers, {
                table  => $name,
                row    => $row_count,
                header => $header,
                skip   => $skip_rows,
            };
        }
        return \@headers;
    },
    handles  => {
        get_header  => 'get',
        all_headers => 'elements',
    },
);

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;
    my $csv  = $self->csv;
    open my $fh, "<:encoding(utf8)", $self->input
        or die "Error opening CSV: $!";
    my $header = $self->get_header(0)->{header};
    my @cols   = @{ $csv->getline($fh) };
    my $row    = {};
    my @records;
    $csv->bind_columns( \@{$row}{@cols} );
    while ( $csv->getline($fh) ) {
        my $record = {};
        foreach my $col (@cols) {
            if (exists $header->{$col}) {
                $record->{ $header->{$col} } = $row->{$col};
            }
            else {
                hurl {
                    ident   => 'csv',
                    message => __x(
                        'Header map <--> CSV file header inconsistency. Column "{col}" not found.',
                        col => $col,
                    )
                };
            }
        }
        push @records, $record;
    }
    close $fh;
    return \@records;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub get_data {
    my $self = shift;
    my $iter = $self->contents_iter;
    my @records;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        # Only records with at least one defined value
        push @records, $row if any { defined($_) } values %{$row};
    }
    return \@records;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 DESCRIPTION

App::Transfer::Reader::CSV - Read a CSV file and return the contents
as AoH.

The input file must be in UTF8 format and the output is also UTF8 to
be inserted in the database.

TODO: Consider Text::CSV::Encoded.  Tests failed for v0.22 with
"Wide character in subroutine entry...".

=cut
