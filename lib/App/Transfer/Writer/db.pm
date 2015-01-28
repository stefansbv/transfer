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

=head1 DESCRIPTION

App::Transfer::Writer::db - Write to a DB.

=cut
