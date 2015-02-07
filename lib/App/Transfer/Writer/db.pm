package App::Transfer::Writer::db;

# ABSTRACT: Writer for Database engines

use 5.010;
use List::Util qw(any);
use Moose;
use MooseX::FileAttribute;
use MooseX::Iterator;
use App::Transfer::X qw(hurl);
use App::Transfer::Target;
use namespace::autoclean;

extends 'App::Transfer::Writer';

use App::Transfer::Target;

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
            uri      => $self->options->uri_str,
            name     => $self->options->target,
        );
    },
);

sub insert {
    my ($self, $table, $columns) = @_;
    my $engine = $self->target->engine;
    if( any { defined } values %{$columns} ) {
        $engine->insert($table, $columns);
        $self->inc_inserted;
    }
    else {
        $self->inc_skipped;
    }
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
