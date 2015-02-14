package App::Transfer::RowTrafos;

# ABSTRACT: Row Transformation methods

use 5.010001;
use utf8;
use Moose;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use namespace::autoclean;

use Data::Dump;

has 'recipe' => (
    is  => 'ro',
    isa => 'App::Transfer::Recipe',
);

has 'transform' => (
    is  => 'ro',
    isa => 'App::Transfer::Transform',
);

has 'engine' => (
    is  => 'ro',
    isa => 'App::Transfer::Engine',
);

has 'info' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    handles => {
        get_info => 'get',
    },
);

has '_trafo_types' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {
            split     => \&type_split,
            join      => \&type_join,
            copy      => \&type_copy,
            batch     => \&type_batch,
            lookup    => \&type_lookup,
            lookup_db => \&type_lookup_db,
        };
        },
    handles => {
        exists_in_type => 'exists',
        get_type       => 'get',
    },
);

sub type_split {
    my ( $self, $step, $record ) = @_;

    my $field_src = $step->field_src;

    hurl type_split => __( "Error in recipe (split): no 'field_src' set" );
    hurl type_split => __( "Error in recipe (split): the 'field_src' attribute must be a string, not a reference") if ref $field_src;
    hurl type_split => __x( "Error in recipe (split): no such field '{field}' for 'field_src'", field => $field_src ) unless exists $record->{$field_src};

    my $p = $self->get_info($field_src);
    hurl field_info =>
        __x( "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency", field => $field_src ) unless defined $p;

    # Make the 'dst' field an array ref if it's not
    my $destination
        = ref $step->field_dst eq 'ARRAY'
        ? $step->field_dst
        : [ $step->field_dst ];

    $p->{logfld}    = $self->get_info('logfld');
    $p->{logidx}    = $self->get_info('logidx');
    $p->{value}     = $record->{$field_src};       # add the value to p
    $p->{limit}     = @{ $destination };       # num fields to return
    $p->{separator} = $step->separator;
    my @values = $self->transform->do_transform( $step->method, $p );
    my $i = 0;
    foreach my $value (@values) {
        my $field_dst = ${$destination}[$i];
        unless ( exists $record->{$field_dst} ) {
            my $field_dst_info = $self->get_info($field_dst);
            hurl field_info => __x(
                "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency", field => $field_dst
            ) unless defined $field_dst_info;
        }
        $record->{$field_dst} = $value;
        $i++;
    }

    return $record;
}

sub type_join {
    my ( $self, $step, $record ) = @_;

    my $fields_src = $step->field_src;
    my $values;
    foreach my $field_src ( @{$fields_src} ) {
        unless ( exists $record->{$field_src} ) {
            hurl type_split =>
                __x( "Error in recipe (join): no such field '{field}'",
                field => $field_src );
        }
        my $field_src_info = $self->get_info($field_src);
        hurl field_info => __x(
            "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
            field   => $field_src,
            context => 'join',
        ) unless defined $field_src_info;

        push @{$values}, $record->{$field_src}
            if defined $record->{$field_src};
    }
    my $field_dst = $step->field_dst;
    my $p         = $self->get_info($field_dst);
    $p->{logfld}     = $self->get_info('logfld');
    $p->{logidx}     = $self->get_info('logidx');
    $p->{separator}  = $step->separator;
    $p->{value}      = $values;
    $p->{fields_src} = $fields_src;
    $record->{$field_dst}
        = $self->transform->do_transform( $step->method, $p );

    return $record;
}

sub type_copy {
    my ( $self, $step, $record ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $p = $self->get_info($field_src);
    $p->{logfld} = $self->get_info('logfld');
    $p->{logidx} = $self->get_info('logidx');

    hurl field_info => __x(
        "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
        field   => $field_src,
        context => 'copy',
    ) unless defined $p;

    $p->{value}       = $record->{$field_src};
    $p->{lookup_list}
        = $self->recipe->datasource->get_valid_list( $step->datasource );
    $p->{field_src}   = $field_src;
    $p->{field_dst}   = $field_dst;
    $p->{attributes}  = $attributes;

    my $r = $self->transform->do_transform( $step->method, $p );
    if ( defined $r ) {

        # Write to destination field
        if ( $attributes->{APPEND} ) {
            if ( exists $r->{$field_dst} ) {
                my $old = $record->{$field_dst};
                my $dst = $old ? "$old, " : "$field_src: ";
                $record->{$field_dst} = $dst . $r->{$field_dst};
            }
        }
        elsif ( $attributes->{APPENDSRC} ) {
            if ( exists $r->{$field_dst} ) {
                my $old = $record->{$field_dst};
                my $dst = $old ? "$old, $field_src: " : "$field_src: ";
                $record->{$field_dst} = $dst . $r->{$field_dst};
            }
        }
        elsif ( $attributes->{REPLACE} ) {
            if ( exists $r->{$field_dst} ) {
                $record->{$field_dst} = $r->{$field_dst};
            }
        }
        elsif ( $attributes->{REPLACENULL} ) {
            if ( exists $r->{$field_dst} ) {
                $record->{$field_dst} = $r->{$field_dst}
                    if not defined $r->{$field_dst};
            }
        }

        # Delete source field value?
        if ( $attributes->{MOVE} ) {
            $record->{$field_src} = undef;
        }
    }

    return $record;
}

sub type_batch {
    my ( $self, $step, $record ) = @_;

    my $fields_src = $step->field_src;
    my $values;
    foreach my $field_src ( @{$fields_src} ) {
        unless ( exists $record->{$field_src} ) {
            hurl type_split =>
                __x( "Error in recipe (batch): no such field '{field}'",
                field => $field_src );
        }
        my $field_src_info = $self->get_info($field_src);
        hurl field_info => __x(
            "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
            field   => $field_src,
            context => 'batch',
        ) unless defined $field_src_info;

        push @{$values}, $record->{$field_src}
            if defined $record->{$field_src};
    }
    my $field_dst = $step->field_dst;
    my $p         = $self->get_info($field_dst);
    $p->{logfld}     = $self->get_info('logfld');
    $p->{logidx}     = $self->get_info('logidx');
    $p->{value}      = $values;
    $p->{fields_src} = $fields_src;
    $p->{attributes} = $step->attributes;
    my $r = $self->transform->do_transform( $step->method, $p );
    foreach my $field_dst ( keys %{$r} ) {
        unless ( exists $record->{$field_dst} ) {
            my $field_dst_info = $self->get_info($field_dst);
            hurl field_info => __x(
                "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency",
                field => $field_dst
            ) unless defined $field_dst_info;
        }
        $record->{$field_dst} = $r->{$field_dst};
    }

    return $record;
}

sub type_lookup {
    my ( $self, $step, $record ) = @_;

    my $field_src = $step->field_src; # XXX
    my $field_dst = $step->field_dst;

    my $p = $self->get_info($field_dst);
    $p->{logfld} = $self->get_info('logfld');
    $p->{logidx} = $self->get_info('logidx');

    hurl field_info => __x(
        "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
        field   => $field_dst,
        context => 'lookup',
    ) unless defined $p;

    $p->{value} = $record->{$field_src};
    $p->{lookup_table}
        = $self->recipe->datasource->get_ds( $step->datasource );

    $record->{$field_dst}
        = $self->transform->do_transform( $step->method, $p );

    return $record;
}

sub type_lookup_db {
    my ( $self, $step, $record ) = @_;

    # say "*** input:";
    # dd $record;

    # Source
    my ($field_src, $src_map);
    if ( ref $step->field_src eq 'HASH' ) {

        # It's a field mapping: source => lookup
        $src_map   = $step->field_src;
        $field_src = ( keys %{ $step->field_src } )[0];
    }
    else {
        $field_src = $step->field_src;
    }

    # say "\n** field_src:";
    # dd $field_src;
    # say "** src map:";
    # dd $src_map;

    # Lookup value
    # my $lookup_val = delete $record->{$field_src}; # XXX delete the source?
    my $lookup_val = $record->{$field_src};
    return $record unless defined $lookup_val; # skip if undef

    # say "\n** lookup_val:";
    # dd $lookup_val;

    # Destination fields and lookup fields
    # Make the 'dst' field an array ref if it's not
    my $destination
        = ref $step->field_dst eq 'ARRAY'
        ? $step->field_dst
        : [ $step->field_dst ];
    my $dst_map    = {};
    my $fields_dst = [];
    my $fields_lkp = [];
    foreach my $rec ( @{$destination} ) {
        if (ref $rec eq 'HASH') {

            # It's a field mapping: lookup => destination
            while ( my ( $key, $val ) = each %{$rec} ) {
                $dst_map->{$key} = $val;
                push @{$fields_dst}, $key;
                push @{$fields_lkp}, $val;
            }
        }
        else {
            push @{$fields_dst}, $rec;
            push @{$fields_lkp}, $rec;
        }
    }

    # say "\n** destination:";
    # dd $fields_dst;
    # say "** dst map:";
    # dd $dst_map;
    # say "** lookup fields:";
    # dd $fields_lkp;

    # Hints
    my $hint_name = $step->hints ;
    if ($hint_name) {
        my $hints = $self->recipe->datasource->get_hints($hint_name);
        if ( exists $hints->{$lookup_val} ) {
            $lookup_val = $hints->{$lookup_val};
        }
    }

    # say "\n** hint lookup_val:";
    # dd $lookup_val;

    # Check if the fields exists in the DB !!! XXX only once !!!
    foreach my $field ( @{$fields_dst} ) {
        my $p = $self->get_info($field);
        hurl field_info => __x(
            "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
            field   => $field,
            context => 'lookup_db',
        ) unless defined $p;
    }

    my $p = {};
    $p->{engine} = $self->engine;
    $p->{table}  = $step->datasource ;
    $p->{logfld} = $self->get_info('logfld');
    $p->{logidx} = $self->get_info('logidx');
    $p->{lookup} = $lookup_val;          # required, used only for loging
    $p->{fields} = $fields_lkp;          # lookup fields list

    # Build WHERE for the lookup
    my $where_fld = ref $src_map ? $src_map->{$field_src} : $field_src;
    $p->{where}{$where_fld} = $lookup_val;

    my $result_aref = $self->transform->do_transform( $step->method, $p );
    foreach my $field ( @{$fields_dst} ) {
        $record->{$field} = shift @{$result_aref};
    }

    return $record;
}

1;

__END__

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Description

=head1 Interface

=head2 Instance Methods

=head3 C<type_split>

=head3 C<type_join>

=head3 C<type_copy>

=head3 C<type_batch>

=head3 C<type_lookup>

=head3 C<type_lookup_db>

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
