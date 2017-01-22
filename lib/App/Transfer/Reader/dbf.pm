package App::Transfer::Reader::dbf;

# ABSTRACT: Reader for DBF files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use XBase;
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

has 'dbf' => (
    is       => 'ro',
    isa      => 'XBase',
    lazy     => 1,
    init_arg => undef,
    default => sub {
        my $self = shift;
        return XBase->new(
            name => $self->input_file,
        ) || die "Cannot use DBF: " . XBase->errstr;
    },
);

has '_headers' => (
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
        my $header    = $self->recipe->tables->get_table($name)->headermap;
        my $skip_rows = $self->recipe->tables->get_table($name)->skiprows;
        my $tempfield = $self->recipe->tables->get_table($name)->tempfield;
        my $row_count = 0;
        push @headers, {
            table  => $name,
            row    => $row_count,
            header => $header,
            skip   => $skip_rows,
            temp   => $tempfield,
        };
    }
    return \@headers;
}

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;
    my $dbf  = $self->dbf;
    my @cols = $dbf->field_names; # field_types, field_lengths, field_decimals
    my $header = $self->get_header(0)->{header};
    my $temp   = $self->get_header(0)->{temp};

    # Add the temporary fields to the record
    foreach my $field ( @{$temp} ) {
        $header->{$field} = $field;
    }

    my @select_cols = keys %{$header};

    # Validate field list
    my @not_found = ();
    foreach my $col (@select_cols) {
        unless ( any { $col eq $_ } @cols ) {
            push @not_found, $col;
        }
    }
    hurl field_info => __x(
        'Header map <--> DBF file header inconsistency. Some columns where not found :"{list}"',
        list  => join( ', ', @not_found ),
    ) if scalar @not_found;

    # Get the data
    my @records;
    my $cursor = $dbf->prepare_select(@select_cols);
    while (my @rec = $cursor->fetch_hashref) {
        push @records, @rec;
    }
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
        push @records, $row; #  if any { defined($_) } values %{$row};
    }
    $self->record_count(scalar @records);
    return \@records;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader::dbf - Reader for DBF files

=head1 Synopsis

  my $reader = App::Transfer::Reader->load( { reader => 'dbf' } );

=head1 Description

App::Transfer::Reader::dbf reads a DBF file and builds a AoH data
structure for the entire contents.

XXX The input file must be in UTF8 format and the output is also UTF8
to be inserted in the database.

=head1 Interface

=head2 Attributes

=head3 C<input_file>

A L<Path::Tiny::File> object representing the Excel input file.

=head3 C<dbf>

A L<DBD::XBase> object representing the DBF input file.

=head3 C<_headers>

An array reference holding info about the table in the file.  The
data-structure contains the table, row, header and skip attributes.

=head3 C<_contents>

An array reference holding the contents of the file.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the DBF file.

=head2 Instance Methods

=head3 C<get_data>

Return an array reference of hash references with the column names as
keys.

=cut
