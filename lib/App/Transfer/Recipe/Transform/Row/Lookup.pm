package App::Transfer::Recipe::Transform::Row::Lookup;

# ABSTRACT: Row transformation step - lookup

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

extends 'App::Transfer::Recipe::Transform::Row::Step';

has 'field_src'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'field_dst'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'datasource' => ( is => 'ro', isa => 'Str', required => 1 );

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_params',
);

sub _build_params {
    my $self = shift;
    my $p = {};
    $p->{datasource} = $self->datasource;
    $p->{field_src}  = $self->field_src;
    $p->{field_dst}  = $self->field_dst;
    $p->{method}     = $self->method;
    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Description

  # Use """ to preserve space, not "'"
  <step>
    type                = split
    separator           = ,
    field_src           = adresa
    method              = split_field
    field_dst           = localitate
    field_dst           = strada
    field_dst           = numarul
  </step>
