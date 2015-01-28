package App::Transfer::Reader::db;

# ABSTRACT: Reader for Database engines

use 5.010;
use List::Compare;
use Moose;
use MooseX::FileAttribute;
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App::Transfer);
use App::Transfer::X qw(hurl);
use App::Transfer::Target;
use namespace::autoclean;

extends 'App::Transfer::Reader';

#- Parameters

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

#- End of parameters

has table => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->source->table, # XXX $self->options->target
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

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self   = shift;
        my $table  = $self->table;
        my $engine = $self->target->engine;
        my $where  = $self->get_header(0)->{where};
        my $order  = $self->get_header(0)->{order};
        my $header = $self->get_header(0)->{header};
        my $fields = $self->get_fields($table);
        my $ah_ref = $engine->records_aoh( $table, $fields, $where, $order );
        my @records;
        foreach my $row ( @{$ah_ref} ) {
            my $record = {};
            foreach my $col ( @{$fields} ) {
                $record->{ $header->{$col} } = $row->{$col};
            }
            push @records, $record;
        }
        return \@records;
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

sub has_table {
    my ($self, $name) = @_;
    die "the name parameter is required!" unless defined $name;
    return $self->recipe->tables->has_table($name);
}

sub get_fields {
    my ($self, $table) = @_;

    my $target = $self->recipe->destination->target;
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
    my $header = $self->recipe->tables->get_table($table)->headermap;
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
            table => $table,
        ),
        }
        if $not_found;

    return \@fields;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub get_data {
    my $self  = shift;
    my $table = $self->table;
    die "Error: no table named '$table'!" unless $self->has_table($table);
    my $iter = $self->contents_iter;
    my @records;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        push @records, $row;
    }
    return \@records;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 DESCRIPTION

App::Transfer::Reader::db - Read from a DB and return the contents as
AoH.

=cut
