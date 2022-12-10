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
use Data::Dump;
use namespace::autoclean;

extends 'App::Transfer::Writer';

has 'header' => (
    is       => 'rw',
    isa      => 'HashRef|ArrayRef',
    required => 1,
);

has 'output_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    lazy     => 1,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        my $file = $self->writer_options->file;
        $file .= '.dbf' unless $file =~ m{\.dbf}i;
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

has 'dbf_stru_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ($stru_file, $stru_file_ext) = ('', 'str');
        if ( my $file = $self->output ) {
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
        hurl __x( "Won't overwrite existing file: {file}",
            file => $self->output )
            if $self->output->is_file;
        say "Creating file: ", $self->output;
        my $dbf = XBase->create(
            name           => $self->output,
            field_names    => $self->field_names,
            field_types    => $self->field_types,
            field_lengths  => $self->field_lengths,
            field_decimals => $self->field_decimals,
        ) or die XBase->errstr;
        return $dbf;
    },
);

sub insert_header { }

sub insert {
    my ( $self, $row, $id ) = @_;
    if ($self->debug) {
        say "# record (before insert):";
        ddx $row;
    }
    if ($self->dbf->set_record( $id, @{$row} ) ) {
        $self->inc_inserted;
    }
    else {
        $self->inc_skipped;
        $self->emit_error;
    }
    return;
}

sub finish {
    my $self = shift;
    $self->dbf->close or hurl io => __x(
        "Cannot close DBF file: {error}",
        error => $!
    );
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

=head1 NAME

App::Transfer::Writer::dbf - Writer for DBF files

=head1 SYNOPSIS

    my $writer = App::Transfer::Writer->load({
        transfer => $transfer,
        recipe   => $recipe,
        writer   => 'dbf',
        reader_options => $reader_options,
        writer_options => $writer_options,
    });
    $writer->insert( $id, $row );

=head1 DESCRIPTION

App::Transfer::Writer::dbf writes a DBF file from an array of data.

=head1 INTERFACE

=head2 ATTRIBUTES

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

=head2 INSTANCE METHODS

=head3 C<insert_header>

Does nothing for DBFs.

=head3 C<insert>

Insert a row of data in the DBF.

=head3 C<emit_error>

Throw an exception if the row of data has problems.

=cut
