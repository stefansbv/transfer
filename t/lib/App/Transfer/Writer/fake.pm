package App::Transfer::Writer::fake;

# ABSTRACT: Writer for FAKE files

use 5.010;
use Moose;
use Data::Dump qw(dump);
use namespace::autoclean;

extends 'App::Transfer::Writer';

with    'App::Transfer::Role::Utils',
        'MooX::Log::Any';

sub insert_header {
    my $self = shift;
    $self->log->info( "[fake] insert header: siruta|denloc|jud" );
    return;
}

sub insert {
    my ( $self, $table, $row ) = @_;
    my $str = dump($row);
    $self->log->info( "[fake] insert row: $str" );
    $self->inc_inserted;
    return;
}

__PACKAGE__->meta->make_immutable;

1;
