package App::Transfer::Reader::fake;

# ABSTRACT: Reader for test

use 5.010;
use Moose;
use namespace::autoclean;

extends 'App::Transfer::Reader';

sub get_data {
    my $self    = shift;
    my @records = (
        {   siruta => 10,
            denloc => "JUDETUL ALBA",
            jud    => 1,
        },
        {   siruta => 1017,
            denloc => "MUNICIPIUL ALBA IULIA",
            jud    => 1,
        },
        {   siruta => 1026,
            denloc => "ALBA IULIA",
            jud    => 1,
        },
    );
    $self->record_count( scalar @records );
    return \@records;
}


__PACKAGE__->meta->make_immutable;

1;
