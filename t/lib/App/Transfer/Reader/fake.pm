package App::Transfer::Reader::fake;

# ABSTRACT: Reader for test

use 5.010;
use Moose;
use MooseX::Iterator;
use namespace::autoclean;

extends 'App::Transfer::Reader';

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;
    my @records;
    foreach my $rec ( @{ $self->get_data } ) {
        push @records, $rec;
        $self->inc_count;
    }
    return \@records;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub get_data {
    my $self    = shift;
    return [
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
    ];
}


__PACKAGE__->meta->make_immutable;

1;
