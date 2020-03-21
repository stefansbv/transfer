package App::Transfer::Transform::Type;

# ABSTRACT: Transformation types

use 5.010001;
use utf8;
use Moose;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use namespace::autoclean;

use App::Transfer::Plugin;

with qw(App::Transfer::Role::Utils
        MooX::Log::Any);

has 'recipe' => (
    is       => 'ro',
    isa      => 'App::Transfer::Recipe',
    required => 1,
);

has 'reader' => (
    is       => 'ro',
    isa      => 'App::Transfer::Reader',
    required => 1,
);

has 'writer' => (
    is       => 'ro',
    isa      => 'App::Transfer::Writer',
    required => 1,
);

has 'plugin_row' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    default => sub {
        return App::Transfer::Plugin->new( plugin_type => 'row' );
    },
);

sub type_split {
    my ( $self, $step, $record, $logstr ) = @_;
    my $field_src = $step->field_src;
    hurl type_split =>
        __x( "Error in recipe (split): no such source field '{field}'",
             field => $field_src ) if !exists $record->{$field_src};
    my $p = {};
    $p->{logstr}    = $logstr;
    $p->{field}     = $step->field_src;
    $p->{limit}     = $step->limit;
    $p->{separator} = $step->separator;
    $p->{value}     = $record->{$field_src};

    my @fields = @{ $step->field_dst };
    my @values = $self->plugin_row->do_transform( $step->method, $p );
    my $i = 0;
    foreach my $field (@fields) {
        my $value = $values[$i];
        $record->{$field} = $value;
        $i++;
    }
    return $record;
}

sub type_join {
    my ( $self, $step, $record, $logstr ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $values_aref = [];
    foreach my $field ( @{ $field_src } ) {
        if ( exists $record->{$field} ) {
            my $value = $record->{$field};
            push @{$values_aref}, $value if defined $value;
        }
        else {
            $self->log->info(
                "$logstr: join: source field '$field' not found in record");
        }
    }
    my $p = {};
    $p->{logstr}      = $logstr;
    $p->{separator}   = $step->separator;
    $p->{values_aref} = $values_aref;

    my $dst_value = $self->plugin_row->do_transform( $step->method, $p );
    $record->{$field_dst} = $dst_value;
    
    # if ( $attributes->{REPLACE} ) {
    #     $record->{$field_dst} = $dst_value;
    # }
    # elsif ( $attributes->{REPLACENULL} ) {
    #     $record->{$field_dst} = $dst_value
    #         if not defined $record->{$field_dst};
    # }

    return $record;
}

sub type_copy {
    my ( $self, $step, $record, $logstr ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $p;
    $p->{logstr}     = $logstr;
    $p->{value}      = $record->{$field_src};
    $p->{field_src}  = $field_src;
    $p->{field_dst}  = $field_dst;
    $p->{attributes} = $attributes;

    if ( $step->datasource ) {
        $p->{lookup_list} =
          $self->recipe->datasource->get_valid_list( $step->datasource );
    }
    if ( $step->valid_regex ) {
        $p->{valid_regex} = $step->valid_regex if $step->valid_regex;
    }
    if ( $step->invalid_regex ) {
        $p->{invalid_regex} = $step->invalid_regex if $step->invalid_regex;
    }
    my $r = $self->plugin_row->do_transform( $step->method, $p );

    if ( ref $r ) {

        # Write to the destination field
        if ( $attributes->{APPEND} ) {
            if ( exists $r->{$field_dst} ) {
                my $old = $record->{$field_dst};
                my $dst = $old ? "$old, " : "";
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
                    if not defined $record->{$field_dst};
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
    my ( $self, $step, $record, $logstr ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $values;
    foreach my $field ( @{$field_src} ) {
        unless ( exists $record->{$field} ) {
            hurl type_batch =>
                __x( "Error in recipe (batch): no such field '{field}'",
                field => $field );
        }
        push @{$values}, $record->{$field}
            if defined $record->{$field};
    }

    my $p;
    $p->{logstr}     = $logstr;
    $p->{value}      = $values;
    $p->{field_src}  = $field_src;
    $p->{field_dst}  = $field_dst;
    $p->{attributes} = $attributes;
    my $r = $self->plugin_row->do_transform( $step->method, $p );
    foreach my $field ( keys %{$r} ) {
        $record->{$field} = $r->{$field};
    }

    return $record;
}

sub type_lookup {
    my ( $self, $step, $record, $logstr ) = @_;

    my $attribs = $step->attributes;

    # Lookup value
    my $field_src  = $step->field_src;
    my $lookup_val = $record->{$field_src};

    return $record unless defined $lookup_val; # skip if undef

    # say "Looking for '$field_src'='$lookup_val'" if $self->debug;

    my $p;
    $p->{logstr}     = $logstr;
    $p->{value}      = $lookup_val;
    $p->{field_src}  = $field_src;
    $p->{lookup_table} = $self->recipe->datasource->get_ds( $step->datasource );
    if ( $step->valid_list ) {
        $p->{valid_list} = $self->recipe->datasource->get_valid_list(
            $step->valid_list
        );
    }
    $p->{attributes} = $attribs;

    $record->{ $step->field_dst }
        = $self->plugin_row->do_transform( $step->method, $p );

    return $record;
}

sub type_lookupdb {
    my ( $self, $step, $record, $logstr ) = @_;

    my $attribs = $step->attributes;

    # Lookup value and where field
    my $lookup_val = $record->{ $step->field_src };
    my $where_fld  = $step->where_fld;

    return $record unless defined $lookup_val; # skip if undef

    # Attributes - ignore diacritics
    if ( $attribs->{IGNOREDIACRITIC} ) {
        $lookup_val = $self->common_RON->translit($lookup_val);
    }
    # Attributes - ignore case
    if ( $attribs->{IGNORECASE} ) {
        $lookup_val = uc $lookup_val;
    }

    # Hints
    if ( my $hint = $step->hints ) {
        if ( my $value = $self->recipe->datasource->hints->get_hint_for(
                $hint, $lookup_val ) ) {
            $lookup_val = $value;
        }
    }

    # Attributes - ignore case
    if ( $attribs->{IGNORECASE} ) {
        $where_fld  = "upper($where_fld)"; # all SQL engines have upper() ??? XXX
        $lookup_val = uc $lookup_val;
    }

    # say "Looking for '$where_fld'='$lookup_val'" if $self->debug;

    # Run-time parameters for the plugin
    my $p;
    $p->{logstr} = $logstr;
    $p->{table}  = $step->table;
    $p->{engine}
        = $step->target eq 'destination'
        ? $self->writer->target->engine
        : $self->reader->target->engine;
    $p->{lookup} = $lookup_val;       # required, used only for loging
    $p->{fields} = $step->fields;
    $p->{where}  = { $where_fld => $lookup_val };
    $p->{attributes} = $attribs;

    my $fld_dst_map = $step->field_dst_map;
    my $result_aref = $self->plugin_row->do_transform( $step->method, $p );
    foreach my $dst_field ( @{ $step->field_dst } ) {
        my $field = $fld_dst_map->{$dst_field};
        $record->{$dst_field} = $result_aref->{$field};
    }

    return $record;
}

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 recipe

=head3 reader

=head3 writer

=head3 plugin_row

=head2 INSTANCE METHODS

=head3 type_split

Split a field into two or more fields, on a separator.

  <step>
    type                = split
    separator           = " "
    field_src           = adresa
    method              = split_field
    field_dst           = localitate
    field_dst           = strada
    field_dst           = numarul
  </step>

=head3 type_join

Join two or more fields into one, with a separator.

  # Use " to preserve space, not '
  <step>
    type                = join
    separator           = ", "
    field_src           = obs1
    field_src           = obs2
    field_src           = obs3
    method              = join_fields
    field_dst           = obs
  </step>

=head3 type_copy

A method best used to cleanup columns about to be normalized.  Using
the C<move_filtered> plug-in, the values not found in a C<datasource>
valid list are moved to the destination column.  Attributes can be
used to alter the format of the destination value.

If the C<datasource> attribute is not set, than all values are
considered to be valid.

Example recipe (from the tests, subtest f.):

  <transform row>
    <step>
      type                = copy
      datasource          = status
      field_src           = status
      method              = move_filtered
      field_dst           = observations
      attributes          = MOVE | APPENDSRC
    </step>
  </transform>

  <datasources>
    <valid_elts status>
      item                = Cancelled
      item                = Disputed
      item                = In Process
      item                = On Hold
      item                = Resolved
      item                = Shipped
    </valid_elts>
  </datasources>

Input records:

  my $records_4f = [
      { status => "Cancelled",      id => 1 },
      { status => "Disputed",       id => 2 },
      { status => "call the owner", id => 3 },
      { status => "On Hold",        id => 4 },
      { status => "tel 1234567890", id => 5, observations => 'some obs' },
      { status => "Shipped",        id => 6 },
  ];

Resulting records:

  my $expected_4f = [
      { id => 1, status => "Cancelled" },
      { id => 2, status => "Disputed" },
      { id => 3, observations => "status: call the owner", status => undef
      },
      { id => 4, status => "On Hold" },
      { id => 5, observations => "some obs, status: tel 1234567890", status => undef
      },
      { id => 6, status => "Shipped" },
  ];


=head3 type_batch

=head3 type_lookup

=head3 type_lookupdb

=cut
