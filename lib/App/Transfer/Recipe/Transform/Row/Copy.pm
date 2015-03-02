package App::Transfer::Recipe::Transform::Row::Copy;

# ABSTRACT: Row transformation step - copy

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

extends 'App::Transfer::Recipe::Transform::Row::Step';

has 'field_src' => ( is => 'ro', isa => 'Str', required => 1 );
has 'field_dst' => ( is => 'ro', isa => 'Str', required => 1 );
has 'attributes' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub {
        return {
            APPEND      => undef,
            APPENDSRC   => undef,
            COPY        => undef,
            MOVE        => undef,
            REPLACE     => undef,
            REPLACENULL => 1,
        };
    },
);
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
    $p->{field_src}   = $self->field_src;
    $p->{field_dst}   = $self->field_dst;
    $p->{attributes}  = $self->attributes;
    $p->{datasource}  = $self->datasource;
    $p->{method}      = $self->method // 'split_field';
    return $p;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    # Check the 'attributes' attribute.  If the default is not used
    # REPLACENULL is not set, and the exception is thrown.  Solution:
    # always set one of the below attribs togheter with COPY or MOVE.
    my $a = $p->{attributes};
    hurl recipe =>
        "Attributes: REPLACE, REPLACENULL, APPEND and APPENDSRC are mutually exclusive!"
        unless ( $a->{REPLACE} xor $a->{REPLACENULL} xor $a->{APPEND}
        xor $a->{APPENDSRC} );

    return $class->$orig( %{$p} );
};

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
