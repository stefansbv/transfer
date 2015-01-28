package App::Transfer::Recipe::Transform;

# ABSTRACT: Data transformation recipe

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use Locale::TextDomain 1.20 qw(App::Transfer);
use namespace::autoclean;

use App::Transfer::Recipe::Transform::Col::Step;
use App::Transfer::Recipe::Transform::Row::Step;

subtype 'ArrayRefColStep',
    as 'ArrayRef[App::Transfer::Recipe::Transform::Col::Step]';

subtype 'ArrayRefRowStep',
    as 'ArrayRef[App::Transfer::Recipe::Transform::Row::Step]';

coerce 'ArrayRefColStep', from 'HashRef[ArrayRef]', via {
    [ map { App::Transfer::Recipe::Transform::Col::Step->new($_) }
            @{ $_->{step} } ];
};

coerce 'ArrayRefRowStep', from 'HashRef[ArrayRef]', via {
    [ map { App::Transfer::Recipe::Transform::Row::Step->new($_) }
            @{ $_->{step} } ];
};

has 'column' => (
    is     => 'ro',
    isa    => 'ArrayRefColStep',
    coerce => 1,
);

has 'row' => (
    is     => 'ro',
    isa    => 'ArrayRefRowStep',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

1;
