package App::Transfer::Recipe::Transform::Row::Lookupdb;

# ABSTRACT: Row transformation step - lookupdb

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use App::Transfer::Recipe::Transform::Types;
use namespace::autoclean;

extends 'App::Transfer::Recipe::Transform::Row::Step';

subtype 'SrcFieldStr'
    => as 'Str';

subtype 'SrcFieldArrayRef'
    => as 'ArrayRef';

subtype 'DstArrayRefOfStrs'
    => as 'ArrayRef[Str]';

subtype 'FieldsArrayRefOfStrs'
    => as 'ArrayRef[Str]';

# From { denloc => "localitate", cod => "siruta" } to ["denloc", "cod"]
coerce 'DstArrayRefOfStrs'
    => from 'HashRef'
    => via { [ keys %{ $_ } ] };

# From { denloc => "localitate", cod => "siruta" } to ["localitate", "siruta"]
coerce 'FieldsArrayRefOfStrs'
    => from 'HashRef'
    => via { [ values %{ $_ } ] };

# From { denloc => "localitate" } to "denloc"
coerce 'SrcFieldStr'
    => from 'HashRef'
    => via { shift [ keys %{ $_ } ] };

# From "denloc" to ["denloc"]
coerce 'DstArrayRefOfStrs'
    => from 'Str'
    => via { [ $_ ] };

# From "denloc" to ["denloc"]
coerce 'FieldsArrayRefOfStrs'
    => from 'Str'
    => via { [ $_ ] };

# From [{ denloc => "localitate" }, "siruta"] to ["denloc", "siruta"]
# From [{ denloc => "localitate" }, { cod => "siruta" }] to ["denloc", "cod"]
coerce 'DstArrayRefOfStrs'
    => from 'ArrayRef'
    => via { [ map { ref $_ ? keys $_ : $_ } @{ $_ } ] };

# From [{ denloc => "localitate" }, "siruta"] to ["localitate", "siruta"]
# From [{ denloc => "localitate" }, { cod => "siruta" }] to ["localitate", "siruta"]
coerce 'FieldsArrayRefOfStrs'
    => from 'ArrayRef'
    => via { [ map { ref $_ ? values $_ : $_ } @{ $_ } ] };

has 'field_src' => (
    is       => 'ro',
    isa      => 'SrcFieldStr',
    required => 1,
    coerce   => 1,
);

has 'field_src_map' => (
    is       => 'rw',
    isa      => 'HashRef|Str',
    init_arg => 'field_src',
    required => 1,
);

has 'field_dst' => (
    is       => 'ro',
    isa      => 'DstArrayRefOfStrs',
    required => 1,
    coerce   => 1,
);

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => 'datasource',
    required => 1,
);

has 'fields' => (
    is       => 'ro',
    isa      => 'FieldsArrayRefOfStrs',
    init_arg => 'field_dst',
    required => 1,
    coerce   => 1,
);

has 'where_fld' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    builder  => '_build_where_fld',
);

sub _build_where_fld {
    my $self   = shift;
    my $srcmap = $self->field_src_map;
    return ref $srcmap ? $srcmap->{ $self->field_src } : $self->field_src;
}

has 'hints' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_params',
);

sub _build_params {
    my $self = shift;
    my $p = {};
    $p->{table}     = $self->table;
    $p->{field_src} = $self->field_src;
    $p->{field_dst} = $self->field_dst;
    $p->{hints}     = $self->hints;
    $p->{fields}    = $self->fields;         # lookup fields list
    $p->{method}    = $self->method // 'lookup_in_dbtable';
    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Description

=cut
