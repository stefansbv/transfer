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
    my $header = $self->header;

    # Add the temporary fields to the record
    # Add the temporary fields to the record
    my $temp = $self->tempfield;
    push @{$header}, @{$temp} if ref $temp eq 'ARRAY';

    # Validate field list
    my @not_found = ();
    foreach my $col ( @{$header} ) {
        unless ( any { $col eq $_ } @cols ) {
            push @not_found, $col;
        }
    }
    hurl field_info => __x(
        'Header map <--> DBF file header inconsistency. Some columns where not found :"{list}"',
        list  => join( ', ', @not_found ),
    ) if scalar @not_found;

    # Get the data
    my @aoh;
    my $cursor = $dbf->prepare_select(@{$header});
    while (my $rec = $cursor->fetch_hashref) {
        push @aoh, $rec;
        $self->inc_count;
    }
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

=head3 C<_contents>

An array reference holding the contents of the file.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the DBF file.

=head2 Instance Methods

=cut
