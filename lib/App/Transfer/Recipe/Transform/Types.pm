package App::Transfer::Recipe::Transform::Types;

# ABSTRACT: Recipe transform types

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'ArrayRefFromStr', as 'ArrayRef';

coerce 'ArrayRefFromStr', from 'Str', via { [ $_ ] };

__PACKAGE__->meta->make_immutable;

1;
