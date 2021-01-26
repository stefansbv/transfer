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

use Data::Dump qw/dump/;

extends 'App::Transfer::Reader';

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'orderby' => (
    is       => 'ro',
    isa      => 'Maybe[Str|ArrayRef|HashRef]',
    required => 0,
);

has 'filter' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef|HashRef]',
    required => 0,
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
    my $engine  = $self->target->engine;
    my $table   = $self->table;
    my $where   = $self->filter;
    my $orderby = $self->orderby;
    my $header  = $self->header;
    if ( $self->debug ) {
        say "# table  = $table";
        say "# where  = ";
        dump $where;
        say "# orderby = ";
        dump $orderby;
        say "---";
    }
    my $fields  = $self->validate_header_fields($table);

    my $ah_ref = $engine->records_aoh( $table, $fields, $where, $orderby );
    $self->record_count( scalar @{$ah_ref} );
    return $ah_ref;
}

sub get_fields {
    my ( $self, $table ) = @_;

    my $engine = $self->target->engine;
    hurl {
        ident   => 'reader',
        exitval => 1,
        message => __x(
            "The '{table}' table does not exists or is not readable",
            table => $table
        ),
      }
      unless $engine->table_exists($table, 'or view');

    # The fields from the table ordered by 'pos'
    my $fields = $engine->get_columns($table);
    if ( $self->debug ) {
        say "Source fields:";
        dump $fields;
    }
    return $fields;
}

sub validate_header_fields {
    my ($self, $table) = @_;
    my $header = $self->header;
    if ($self->debug) {
        say "Header fields:";
        dump $header;
    }
    my $fields = $self->get_fields($table);
    my $lc        = List::Compare->new( $fields, $header );
    my @fields_cm = $lc->get_intersection;
    my $not_found = join ' ', $lc->get_complement;
    hurl {
        ident   => 'reader',
        exitval => 1,
        message => __x(
            "Columns from the header not found in the '{table}' table: '{list}'",
            list  => $not_found,
            table => $table,
        ),
    } if $not_found;
    return \@fields_cm;
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

=head3 C<get_fields>

=cut
