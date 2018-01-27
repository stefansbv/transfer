package App::Transfer::Recipe::Transform::Types;

# ABSTRACT: Recipe transform types

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'ArrayRefFromStr', as 'ArrayRef';

subtype 'CoordsFromStr', as 'ArrayRef';

coerce 'ArrayRefFromStr', from 'Str', via { [$_] };

coerce 'CoordsFromStr', from 'Str', via { [ split /\s*,\s*/, $_ ] };

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform::Types - Definition of attribute data types

=head1 Synopsis

  use App::Transfer::Recipe::Transform::Types;

=head1 Description

This module defines data types use in Transfer object
attributes. Supported types are:

=over

=item C<ArrayRefFromStr>

An array reference coerced from string.

=back

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

=cut
