package App::Transfer::Recipe::Types;

# ABSTRACT: Recipe types

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'Natural', as 'Int', where { $_ > 0 };

# This must be set to the current recipe format version
subtype 'NaturalLessThanN', as 'Natural', where { $_ <= 2 },
    message { "The number ($_) is not <= 2!" };

__PACKAGE__->meta->make_immutable;

1;
