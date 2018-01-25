package App::Transfer::Writer::dbf;

# ABSTRACT: Writer for DBF files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File Path);
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use XBase;
use Path::Tiny;
use File::Basename;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

extends 'App::Transfer::Writer';

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

has 'dbf_stru_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ($stru_file, $stru_file_ext) = ('', 'str');
        if ( my $file = $self->output_file ) {
            my ( $name, $path, $ext ) = fileparse( $file, qr/\.[^\.]*/ );
            $stru_file_ext = uc $stru_file_ext if $ext eq uc $ext;
            $stru_file = path( $path, "${name}.${stru_file_ext}" );
            hurl __x( "Could not find the structure file (check the case of the extension): {file}",
                file => $stru_file )
                unless $stru_file and $stru_file->is_file;
        }
        return $stru_file;
    },
);

has 'dbf_stru_cols' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        return [qw(FIELD_NAME FIELD_TYPE FIELD_LEN FIELD_DEC FIELD_IDX)];
    },
);

has [qw(field_names field_types field_lengths field_decimals)] => (
    is       => 'rw',
    isa      => 'ArrayRef',
    lazy     => 1,
    init_arg => undef,
    default  => sub { [] },
);

has 'dbf_stru' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    init_arg => undef,
    default => sub {
        my $self = shift;
        my $dbf = XBase->new(
            name => $self->dbf_stru_file,
        ) || die "Cannot use DBF: " . XBase->errstr;
        my (@records, @names, @types, @lens, @decs);
        my $cursor = $dbf->prepare_select( @{$self->dbf_stru_cols} );
        while (my $rec = $cursor->fetch_hashref) {
            push @records, $rec;
            push @names, $rec->{FIELD_NAME};
            push @types, $rec->{FIELD_TYPE};
            push @lens, $rec->{FIELD_LEN};
            push @decs, $rec->{FIELD_DEC};
        }
        $self->field_names(\@names);
        $self->field_types(\@types);
        $self->field_lengths(\@lens);
        $self->field_decimals(\@decs);
        return \@records;
    },
);

has 'dbf' => (
    is       => 'ro',
    isa      => 'XBase',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        hurl __x( "Wont overwrite existing file: {file}",
            file => $self->output_file )
            if $self->output_file->is_file;
        say "Creating file: ", $self->output_file;
        my $dbf = XBase->create(
            name           => $self->output_file,
            field_names    => $self->field_names,
            field_types    => $self->field_types,
            field_lengths  => $self->field_lengths,
            field_decimals => $self->field_decimals,
        ) or die XBase->errstr;
        return $dbf;
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

sub insert_header {

}

sub insert {
    my ( $self, $id, $row ) = @_;
    if ($self->dbf->set_record( $id, @{$row} ) ) {
        $self->inc_inserted;
    }
    else {
        $self->inc_skipped;
        $self->emit_error;
    }
    return;
}

sub emit_error {
    my ($self, $dbf_o) = @_;
    my $error = XBase->errstr;
    hurl io => __x(
        'DBF error: {error}',
        error => $error,
    );
    return;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Writer::dbf - Writer for DBF files

=head1 Synopsis

  my $writer = App::Transfer::Writer->load( { writer => 'dbf' } );

=head1 Description

App::Transfer::Writer::dbf reads a DBF file and builds a AoH data
structure for the entire contents.

The input file must be in UTF8 format and the output is also UTF8 to
be inserted in the database.

TODO: Consider Text::DBF::Encoded.  Tests failed for v0.22 with
"Wide character in subroutine entry...".

=head1 Interface

=head2 Attributes

=head3 C<output_file>

A L<Path::Tiny::File> object representing the DBF output file.

=head3 C<dbf_stru_file>

The DBF structure file name.  The extension is C<str> or C<STR>.  If
the DBF file extension is in uppercase, than it also returns an
uppercase name.

=head3 C<dbf_stru_cols>

=head3 C<field_names>

=head3 C<field_types>

=head3 C<field_lengths>

=head3 C<field_decimals>

=head3 C<dbf_stru>

=head3 C<dbf>

A L<Text::DBF> object.

=head3 C<_headers>

An array reference holding info about the table in the file.  The
data-structure contains the table, row, header and skip attributes.

=head2 Instance Methods

=head3 C<insert_header>

Insert the header row in the DBF.

=head3 C<insert>

Insert a row of data in the DBF.

=head3 C<emit_error>

Throw an exception if the row of data has problems.

=cut
