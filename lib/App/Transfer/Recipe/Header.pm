package App::Transfer::Recipe::Header;

# ABSTRACT: Data transformation recipe parser

use 5.010001;
use Moose;
use namespace::autoclean;

has 'version'       => ( is => 'ro', isa => 'Natural' );
has 'syntaxversion' => ( is => 'ro', isa => 'NaturalLessThanN' );
has 'name'          => ( is => 'ro', isa => 'Str' );
has 'description'   => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

1;
