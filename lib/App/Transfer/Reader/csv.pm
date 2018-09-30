package App::Transfer::Reader::csv;

# ABSTRACT: Reader for CSV files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use Text::CSV;
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

has 'csv' => (
    is       => 'ro',
    isa      => 'Text::CSV',
    lazy     => 1,
    init_arg => undef,
    default => sub {
        return Text::CSV->new( {
            sep_char       => ';',
            always_quote   => 0,
            binary         => 1,
            blank_is_undef => 1,
        } ) || die "Cannot use CSV: " . Text::CSV->error_diag();
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
    open my $fh, "<:encoding(utf8)", $self->input_file
        or die "Error opening CSV: $!";

    my @header = @{ $self->header };
    hurl field_info => __('[EE] Empty table header in the recipe file?')
        if scalar @header == 0;

    my @csv_cols = @{ $csv->getline($fh) };
    # bind_columns returns weird data when the $row pushed to an
    # array
    $csv->column_names(@csv_cols);

    # Validate field list
    if ( any { ! defined $_ } @csv_cols ) {
        hurl field_info => __x(
            '[EE] At least a column is not defined in the CSV header list "{list}"',
            list => join( ', ', @csv_cols ),
        );
    }
    else {
        say "# reader CSV header: \n# ", join ', ', @csv_cols if $self->debug;
    }
    my @not_found = ();
    foreach my $col (@header) {
        unless ( any { $col eq $_ } @csv_cols ) {
            push @not_found, $col;
        }
    }
    hurl field_info => __x(
        'Recipe header <--> CSV file header inconsistency.
           Some columns where not found :"{list}"',
        list  => join( ', ', @not_found ),
    ) if scalar @not_found;

    # Get the data, only for non empty records and fields of the
    # header
    my @aoh = ();
    while ( my $row = $csv->getline_hr($fh) ) {
        my $record = {};
        if ( any { defined($_) } values %{$row} ) {
            foreach my $field (@header) {
                $record->{$field} = $row->{$field};
            }
            push @aoh, $record;
            $self->inc_count;
        }
        else {
            $self->inc_skip;
        }
    }
    close $fh;
    return \@aoh;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader::csv - Reader for CSV files

=head1 Synopsis

  my $reader = App::Transfer::Reader->load( { reader => 'csv' } );

=head1 Description

App::Transfer::Reader::csv reads a CSV file and builds a AoH data
structure for the entire contents.

The input file must be in UTF8 format and the output is also UTF8 to
be inserted in the database.

TODO: Consider Text::CSV::Encoded.  Tests failed for v0.22 with
"Wide character in subroutine entry...".

=head1 Interface

=head2 Attributes

=head3 C<input_file>

A L<Path::Tiny::File> object representing the Excel input file.

=head3 C<csv>

A L<Text::CSV> object representing the CSV input file.

=head3 C<_contents>

An array reference holding the contents of the file.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the CSV file.

=head2 Instance Methods

=cut
