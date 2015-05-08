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

subtype 'DstMapHashRefs'
    => as 'HashRef';

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
    => via { shift @{ [ keys %{ $_ } ] } };

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
    => via { [ map { ref $_ ? keys %{ $_ } : $_ } @{ $_ } ] };

# From [{ denloc => "localitate" }, "siruta"] to ["localitate", "siruta"]
# From [{ denloc => "localitate" }, { cod => "siruta" }] to ["localitate", "siruta"]
coerce 'FieldsArrayRefOfStrs'
    => from 'ArrayRef'
    => via { [ map { ref $_ ? values %{ $_ } : $_ } @{ $_ } ] };

# From [ { denloc => "localitate" }, "siruta" ]
#  to { localitate => "denloc", siruta => "siruta" }
# From [ { denloc => "localitate" }, { cod => "siruta" } ]
#  to { localitate => "denloc", siruta => "cod" }
coerce 'DstMapHashRefs'
    => from 'ArrayRef'
    => via { aoh2h($_) };

coerce 'DstMapHashRefs'
    => from 'HashRef'
    => via { %{ $_ } };

coerce 'DstMapHashRefs'
    => from 'Str'
    => via { str2h($_) };

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

has 'field_dst_map' => (
    is       => 'ro',
    isa      => 'DstMapHashRefs',
    init_arg => 'field_dst',
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

sub aoh2h {
    my $rec = shift;
    my %h;
    foreach my $item ( @{$rec} ) {
        if ( ref $item ) {
            while ( my ( $k, $v ) = each %{$item} ) {
                $h{$k} = $v;
            }
        }
        else {
            $h{$item} = $item;
        }
    }
    return \%h;
}

sub str2h {
    my $item = shift;
    my %h;
    $h{$item} = $item;
    return \%h;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Transform::Row::Lookupdb - Row transformation step - lookupdb

=head1 Synopsis

   my $steps = App::Transfer::Recipe::Transform::Row::Lookupdb->new(
      $self->recipe_data->{step},
   );

Where the C<step> type is C<lookupdb>.

=head1 Description

An object representing a C<row> recipe transformations C<step> section
with the type attribute set to C<lookupdb>.

The purpose of this transformation is to normalize the records of a
table.

Example <lookupdb> row transformation steps:

  # a.
  <step>
    type                = lookupdb
    datasource          = test_dict
    hints               = localitati
    <field_src>
      denumire          = localitate
    </field_src>
    method              = lookup_in_dbtable
    <field_dst>
      denloc            = localitate
    </field_dst>
    <field_dst>
      cod               = siruta
    </field_dst>
  </step>

  # b.
  <step>
    type                = lookupdb
    datasource          = test_dict
    hints               = localitati
    <field_src>
      denumire          = localitate
    </field_src>
    method              = lookup_in_dbtable
    <field_dst>
      denloc            = localitate
      cod               = siruta
    </field_dst>
  </step>

  # c.
  <step>
    type                = lookupdb
    datasource          = test_dict
    hints               = localitati
    <field_src>
      denumire          = localitate
    </field_src>
    method              = lookup_in_dbtable
    <field_dst>
      denloc            = localitate
    </field_dst>
    field_dst           = siruta
  </step>

  # d.
  <step>
    type                = lookupdb
    datasource          = test_dict
    field_src           = localitate
    method              = lookup_in_dbtable
    field_dst           = siruta
  </step>

In all the examples, the dictionary table has two columns
C<localitate> and C<siruta>.

The a. and b. configurations are equivalent:

The destination table have a C<denloc> and a C<cod> field.

The source table for the a. and b. examples have a C<denumire> field
and with the value of this field we are searching the dictionary for
the corresponding C<siruta> code and write it to the C<cod> field of
the destination table and the above mentioned value is also copied to
the C<denloc> field.

The C<field-src> is C<denumire> and has a mapping to the C<localitate>
field from the dictionary table.  The destination fields C<denloc> and
C<cod> have mappings to C<localitate> and <siruta> fields from the
dictionary.

The c. configuration has a different destination field C<siruta>
instead of C<cod>, so no mapping is required.

The d. configuration has no mappings at all, the names of the source,
dictionary and destination fields match.

=head1 Interface

=head3 C<new>

Instantiates and returns an
L<App::Transfer::Recipe::Transform::Row::Copy> object.

   my $steps = App::Transfer::Recipe::Transform::Row::Copy->new(
      $self->recipe_data->{step},
   );

Where the C<step> type is C<copy>.

=head2 Attributes

=head3 C<field_src>

The source field name string.

=head3 C<field_src_map>

The source field mapping hash reference.

=head3 C<field_dst>

The destination field name string.

=head3 C<table>

The dictionary table name string from the C<datasource> configuration
attribute.

=head3 C<fields>

The list of the columns passed to the database lookup operation.

=head3 C<where_fld>

The C<field_src> or the value of the mapping source field mapping hash
reference.

=head3 C<hints>

A dictionary type data structure.  Can be used to fix frequently made
user spelling mistakes in a database column.  For example when looking
for C<THIS> actually look for C<THAT>.

=head3 C<params>

Returns a hash reference with all the attributes.  It is passed to the
plugin method.

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
