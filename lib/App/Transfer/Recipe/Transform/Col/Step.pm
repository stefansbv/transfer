package App::Transfer::Recipe::Transform::Col::Step;

# ABSTRACT: Data transformation recipe

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use App::Transfer::Recipe::Transform::Types;

has 'field' => ( is => 'ro', isa => 'Str' );

has 'method' => (
    is     => 'ro',
    isa    => 'ArrayRefFromStr',
    coerce => 1
);

__PACKAGE__->meta->make_immutable;

1;
