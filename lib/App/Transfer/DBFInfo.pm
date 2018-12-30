package App::Transfer::DBFInfo;

# ABSTRACT: Info for DBF files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use XBase;
use App::Transfer::X qw(hurl);
use Data::Dump;
use namespace::autoclean;

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
    default  => sub {
        my $self = shift;
        return XBase->new(
            name => $self->input_file,
        ) || die "Cannot use DBF: " . XBase->errstr;
    },
);

sub get_columns {
    my $self = shift;
    my $dbf  = $self->dbf;
    my @fields = $dbf->field_names;
    return \@fields;
}

has _structure_meta => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_structure_meta',
);

sub _build_structure_meta {
    my $self = shift;
    my $info = {};
    my $pos  = 1;
    my $dbf  = $self->dbf;
    foreach my $field ( @{ $self->get_columns } ) {
        $info->{$field} = {
            pos    => $pos,
            name   => $field,
            type   => $dbf->field_type($field),
            length => $dbf->field_length($field),
            prec   => undef,
            scale  => $dbf->field_decimal($field),
        };
        $pos++;
    }
    return $info;
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

=head1 Interface

=head2 Attributes

=head3 C<input_file>

A L<Path::Tiny::File> object representing the DBF input file.

=head3 C<dbf>

A L<DBD::XBase> object instance.

=head3 C<_structure_meta>

An array reference holding the contents of the file.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the DBF file.

=head2 Instance Methods

=cut
