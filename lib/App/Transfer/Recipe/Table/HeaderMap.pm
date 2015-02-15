package App::Transfer::Recipe::Table::HeaderMap;

# ABSTRACT: Data transformation recipe parser

use 5.010001;
use Moose;
use namespace::autoclean;

has 'description' => ( is => 'ro', isa => 'Str' );
has 'skiprows'    => ( is => 'ro', isa => 'Int' );
has 'logfield'    => ( is => 'ro', isa => 'Str' );

has 'headermap' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { {} },
);


__PACKAGE__->meta->make_immutable;

1;
