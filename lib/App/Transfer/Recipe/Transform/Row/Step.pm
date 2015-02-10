package App::Transfer::Recipe::Transform::Row::Step;

# ABSTRACT: Data transformation recipe

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'type'       => ( is => 'ro', isa => 'Str',            required => 1 );
has 'method'     => ( is => 'ro', isa => 'Str',            required => 1 );
has 'field_src' => (
    is       => 'ro',
    isa      => 'Str | ArrayRef | HashRef',
    required => 1,
);
has 'field_dst'  => ( is => 'ro', isa => 'Str | ArrayRef', required => 1 );

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

has 'separator'  => ( is => 'ro', isa => 'Str' );
has 'datasource' => ( is => 'ro', isa => 'Str' );
has 'hints'      => ( is => 'ro', isa => 'Str' );

sub BUILD {
    my $self = shift;
    my ($attr) = @_;

    if ( $self->type eq 'split' or $self->type eq 'join' ) {
    hurl recipe =>
        "A 'separator' attribute is required for 'split' and 'join' transformations!"
        unless $self->separator;
    }

    if (   $self->type eq 'copy'
        or $self->type eq 'lookup'
        or $self->type eq 'lookup_db' )
        {
    hurl recipe =>
        "A 'datasource' attribute is required for 'copy', 'lookup' and 'lookup_db' transformations!"
        unless $self->datasource;
    }

    # Check the 'attributes' attribute.
    # If the default is not used REPLACENULL is not set, and the
    # exception is thrown.
    # Solution: always set one of the below attribs togheter with COPY
    # or MOVE.
    my $a = $self->attributes;
    hurl recipe =>
        "Attributes: REPLACE, REPLACENULL, APPEND and APPENDSRC are mutually exclusive!"
        unless ( $a->{REPLACE} xor $a->{REPLACENULL} xor $a->{APPEND}
        xor $a->{APPENDSRC} );
};

__PACKAGE__->meta->make_immutable;

1;
