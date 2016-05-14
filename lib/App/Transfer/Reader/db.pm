package App::Transfer::Reader::db;

# ABSTRACT: Reader for Database engines

use 5.010001;
use List::Compare;
use Hash::Merge qw(merge);
use Moose;
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use App::Transfer::Target;
use namespace::autoclean;

extends 'App::Transfer::Reader';

has 'src_table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->source->table,
    },
);

has 'dst_table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->destination->table,
    },
);

has 'target' => (
    is      => 'ro',
    isa     => 'App::Transfer::Target',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Target->new(
            transfer => $self->transfer,
            uri      => $self->options->uri_str,
            name     => $self->options->target,
        );
    },
);

has '_contents' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self    = shift;
    my $table   = $self->src_table;
    my $engine  = $self->target->engine;
    my $where = Hash::Merge->new->merge(
        $self->get_header(0)->{where},
        $self->get_header(0)->{filter},
    );
    my $orderby = $self->get_header(0)->{orderby};
    my $header  = $self->get_header(0)->{header};
    my $fields  = $self->get_fields($table);
    my $ah_ref  = $engine->records_aoh( $table, $fields, $where, $orderby );
    my @records;
    foreach my $row ( @{$ah_ref} ) {
        my $record = {};
        foreach my $col ( @{$fields} ) {
            $record->{ $header->{$col} } = $row->{$col};
        }
        push @records, $record;
    }
    return \@records;
}

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
        my $row_count = 0;
        push @headers,
            {
            table   => $name,
            row     => $row_count,
            header  => $self->recipe->tables->get_table($name)->headermap,
            skip    => $self->recipe->tables->get_table($name)->skiprows,
            orderby => $self->recipe->tables->get_table($name)->orderby,
            };
    }
    return \@headers;
}

sub has_table {
    my ($self, $name) = @_;
    die "the name parameter is required!" unless defined $name;
    return $self->recipe->tables->has_table($name);
}

sub get_fields {
    my ($self, $table) = @_;

    my $engine = $self->target->engine;
    hurl {
        ident   => 'reader',
        exitval => 1,
        message => __x( 'Table "{table}" does not exists', table => $table ),
    } unless $engine->table_exists($table);

    # The fields from the table ordered by 'pos'
    my $fields_href = $engine->get_info($table);
    my @table_fields = keys %{$fields_href};

    # The fields from the header map
    my $dst_table = $self->dst_table;
    my $recipe_table = $self->recipe->tables->get_table($dst_table);
    hurl {
        ident   => 'reader',
        exitval => 1,
        message => __x(
            'Table "{table}" has no header-map in the recipe',
            table => $dst_table ),
    } unless $recipe_table;
    my $header = $recipe_table->headermap;
    my @hmap_fields = keys %{$header};

    my $lc = List::Compare->new( \@table_fields, \@hmap_fields );
    my @fields    = $lc->get_intersection;
    my $not_found = join ' ', $lc->get_complement;
    hurl {
        ident   => 'reader',
        exitval => 1,
        message => __x(
            q{Columns from the map file not found in the "{table}" table: "{list}"},
            list  => $not_found,
            table => $dst_table,
        ),
        } if $not_found;

    return \@fields;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub get_data {
    my $self   = shift;
    my $table  = $self->src_table;
    my $engine = $self->target->engine;
    hurl {
        ident   => 'reader',
        exitval => 1,
        message => __x( 'Table "{table}" does not exists', table => $table ),
    } unless $engine->table_exists($table);
    my $iter = $self->contents_iter;
    my @records;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        push @records, $row;
    }
    $self->record_count(scalar @records);
    return \@records;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader::db - Reader for database tables

=head1 Synopsis

  my $reader = App::Transfer::Reader->load( { reader => 'db' } );

=head1 Description

App::Transfer::Reader::db reads from a database table and
builds a AoH data structure for the entire contents.

=head1 Interface

=head2 Attributes

=head3 C<table>

The name of the source table.

=head3 C<target>

The L<App::Transfer::Targe> object.

=head3 C<_headers>

An array reference holding info about the table.  The data-structure
contains the table name, row, header and skip attributes. XXX

=head3 C<_contents>

An array reference holding the contents of the table.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the table.

=head2 Instance Methods

=head3 C<has_table>

Return true if the table C<$name> is defined in the recipe (actually
returns the name of the table or undef).

=head3 C<get_data>

Return an array reference of hashes, where the hash keys are the names
of the columns and the values are the values read from the table
columns. (XXX reformulate).

=head3 C<get_fields>

=head3 C<get_data>

Return an array reference of hashes, where the hash keys are the names
of the columns and the values are the values read from the table
columns. (XXX reformulate).

=cut
