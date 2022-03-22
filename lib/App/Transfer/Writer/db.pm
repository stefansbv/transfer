package App::Transfer::Writer::db;

# ABSTRACT: Writer for Database engines

use 5.010;
use List::Util qw(any);
use Moose;
use MooseX::Iterator;
use App::Transfer::X qw(hurl);
use App::Transfer::Target;
use Data::Dump;
use namespace::autoclean;

extends 'App::Transfer::Writer';

has table => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->destination->table;
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
            uri      => $self->writer_options->uri_str,
            name     => $self->writer_options->target,
        );
    },
);

sub insert {
    my ($self, $row, $table) = @_;
    if ($self->debug) {
        say "record (before insert):";
        ddx $row;
    }
    my $engine = $self->target->engine;
    if( any { defined } values %{$row} ) {
        $engine->insert($table, $row);
        $self->inc_inserted;
    }
    else {
        $self->inc_skipped;
    }
    return;
}

sub table_truncate {
    my ($self, $table) = @_;
    my $engine = $self->target->engine;
    $engine->table_truncate($table);
    return;
}

sub reset_sequence {
    my ($self, $seq) = @_;
    my $engine = $self->target->engine;
    $engine->reset_sequence($seq);
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Writer::db - Writer for database tables

=head1 Synopsis

  my $writer = App::Transfer::Writer->load( { writer => 'db' } );

=head1 Description

App::Transfer::Writer::db writes to a database table.

=head1 Interface

=head2 Attributes

=head3 C<table>

The name of the source table.

=head3 C<target>

The L<App::Transfer::Targe> object.

=head2 Instance Methods

=head3 C<insert>

Insert a record in the database table.

The parameters are:

=over

=item C<$table>

The name of the table.

=item C<$columns>

A hash reference of column names and values.

=back

=cut
