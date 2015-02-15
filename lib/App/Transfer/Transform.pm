package App::Transfer::Transform;

# ABSTRACT: Transformation methods

use 5.010001;
use utf8;
use Moose;
use MooseX::Iterator;
use MooseX::Types::Path::Tiny qw(Path File);
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use Perl6::Form;
use namespace::autoclean;

use App::Transfer::Options;
use App::Transfer::Recipe;
use App::Transfer::Reader;
use App::Transfer::Writer;
use App::Transfer::Plugin;

with qw(App::Transfer::Role::Utils
        MooseX::Log::Log4perl);

has 'transfer' => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
);

has 'recipe_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

has 'input_options' => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'output_options' => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'recipe' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe->new(
            recipe_file => $self->recipe_file->stringify,
        );
    },
);

has 'reader_options' => (
    is      => 'ro',
    isa     => 'App::Transfer::Options',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Options->new(
            transfer => $self->transfer,
            recipe   => $self->recipe,
            options  => $self->input_options,
            rw_type  => 'reader',
        );
    },
);

has 'writer_options' => (
    is      => 'ro',
    isa     => 'App::Transfer::Options',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Options->new(
            transfer => $self->transfer,
            recipe   => $self->recipe,
            options  => $self->output_options,
            rw_type  => 'writer',
        );
    },
);

has 'reader' => (
    is       => 'ro',
    isa      => 'App::Transfer::Reader',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return App::Transfer::Reader->load({
            transfer => $self->transfer,
            recipe   => $self->recipe,
            reader   => $self->recipe->source->reader,
            options  => $self->reader_options,
        });
    },
);

has 'writer' => (
    is       => 'ro',
    isa      => 'App::Transfer::Writer',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return App::Transfer::Writer->load({
            transfer => $self->transfer,
            recipe   => $self->recipe,
            writer   => $self->recipe->destination->writer,
            options  => $self->writer_options,
        });
    },
);

has 'plugin' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    default => sub {
        return App::Transfer::Plugin->new;
    },
);

has 'engine' => (
    is  => 'ro',
    isa => 'App::Transfer::Engine',
);

has 'info' => (
    traits   => ['Hash'],
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    handles  => {
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

has '_contents' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->reader->get_data;
    },
);

has '_contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub type_split {
    my ( $self, $step, $record ) = @_;

    my $field_src = $step->field_src;

    hurl type_split => __( "Error in recipe (split): no 'field_src' set" );
    hurl type_split => __( "Error in recipe (split): the 'field_src' attribute must be a string, not a reference") if ref $field_src;
    hurl type_split => __x( "Error in recipe (split): no such field '{field}' for 'field_src'", field => $field_src ) unless exists $record->{$field_src};

    my $p = {};
    # my $p = $self->get_info($field_src);
    # hurl field_info =>
    #     __x( "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency", field => $field_src ) unless defined $p;

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
    my @values = $self->plugin->do_transform( $step->method, $p );
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
        # my $field_src_info = $self->get_info($field_src);
        # hurl field_info => __x(
        #     "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
        #     field   => $field_src,
        #     context => 'join',
        # ) unless defined $field_src_info;

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
        = $self->plugin->do_transform( $step->method, $p );

    return $record;
}

sub type_copy {
    my ( $self, $step, $record ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $p = {};
    # my $p = $self->get_info($field_src);
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

    my $r = $self->plugin->do_transform( $step->method, $p );
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
        # my $field_src_info = $self->get_info($field_src);
        # hurl field_info => __x(
        #     "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
        #     field   => $field_src,
        #     context => 'batch',
        # ) unless defined $field_src_info;

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
    my $r = $self->plugin->do_transform( $step->method, $p );
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
        = $self->plugin->do_transform( $step->method, $p );

    return $record;
}

sub build_lookup_db_para {
    my ( $self, $step ) = @_;

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

    # Destination fields and lookup fields
    # Make the 'dst' field an array ref if it's not
    my $destination
        = ref $step->field_dst eq 'ARRAY'
        ? $step->field_dst
        : [ $step->field_dst ];
    # my $dst_map    = {};
    my $fields_dst = [];
    my $fields_lkp = [];
    foreach my $rec ( @{$destination} ) {
        if (ref $rec eq 'HASH') {

            # It's a field mapping: lookup => destination
            while ( my ( $key, $val ) = each %{$rec} ) {
                # $dst_map->{$key} = $val;
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

    # # Check if the destination fields exists in the DB XXX
    # foreach my $field ( @{$fields_dst} ) {
    #     my $p = $self->get_info($field);
    #     hurl field_info => __x(
    #         "Field info for '{field}' not found!  Recipe <--> DB schema inconsistency ({context})",
    #         field   => $field,
    #         context => 'lookup_db',
    #     ) unless defined $p;
    # }

    my $p = {};
    $p->{engine}    = $self->engine;
    $p->{method}    = $step->method;
    $p->{table}     = $step->datasource;
    $p->{field_src} = $field_src;
    $p->{field_dst} = $fields_dst;
    $p->{src_map}   = $src_map;

    #$p->{dst_map} = $dst_map;
    $p->{hint}   = $step->hints;
    #$p->{logstr} =
    $p->{fields} = $fields_lkp;                 # lookup fields list

    return $p;
}

sub type_lookup_db {
    my ( $self, $p, $record ) = @_;

    # say "*** input:";
    # dd $record;
    my $field_src = $p->{field_src};
    my $field_dst = $p->{field_dst};

    # Lookup value
    # my $lookup_val = delete $record->{$field_src}; # XXX delete the source?
    my $lookup_val = $record->{$field_src};
    return $record unless defined $lookup_val; # skip if undef

    # say "\n** lookup_val:";
    # dd $lookup_val;

    # Hints
    if ( my $hint = $p->{hint} ) {
        my $hints = $self->recipe->datasource->get_hints($hint);
        if ( exists $hints->{$lookup_val} ) {
            $lookup_val = $hints->{$lookup_val};
        }
    }
    # say "\n** hint lookup_val:";
    # dd $lookup_val;

    # Build WHERE for the lookup
    $p->{lookup}  = $lookup_val;       # required, used only for loging

    my $src_map   = $p->{src_map};
    my $where_fld = ref $src_map ? $src_map->{$field_src} : $field_src;
    $p->{where}{$where_fld} = $lookup_val;

    my $result_aref = $self->plugin->do_transform( $p->{method}, $p );
    foreach my $field ( @{$field_dst} ) {
        $record->{$field} = shift @{$result_aref};
    }

    return $record;
}

###

sub job_intro {
    my $self = shift;

    #-- Recipe

    my $recipe_l = __ 'Recipe:';
    my $recipe_v = $self->recipe->header->name;
    my @recipe_ldet
        = ( __ 'version:', __ 'syntax version:', __ 'description:' );
    my @recipe_vdet = (
        $self->recipe->header->version,
        $self->recipe->header->syntaxversion,
        $self->recipe->header->description,
    );
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    $recipe_l,                                                     $recipe_v;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@recipe_ldet,                                             \@recipe_vdet;

    return;
}

sub transfer_file2db {
    my $self = shift;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    $self->job_info_file2db($engine->database);

    hurl run => __x("No input file specified; use '--if' or set the source file in the recipe.") unless $self->reader_options->file;

    hurl run => __x("Invalid input file specified; use '--if' or fix the source file in the recipe.") unless -f $self->reader_options->file->stringify;

    hurl run => __x("The table '{table}' does not exists!",
        table => $table) unless $engine->table_exists($table);

    my $table_info = $engine->get_info($table);

    hurl run => __ 'No columns type info retrieved from database!'
        if keys %{$table_info} == 0;

    # Log field name
    my $logfld = $self->recipe->tables->get_table($table)->logfield;
    unless ($logfld) {
        my @cols = $self->sort_hash_by_pos($table_info);
        $logfld = shift @cols;              # that the first column is
    }

    my $iter = $self->_contents_iter;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        $row    = $self->do_transformations($row, $table_info, $logfld);
        $self->writer->insert($table, $row);

        #last;                                # DEBUG
    }

    return;
}

sub job_info_file2db {
    my ($self, $database) = @_;

    #-- Input

    my $input_l  = __ 'Input:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                  $input_l;

    my $worksheet = $self->reader->worksheet
        if $self->reader->can('worksheet');
    $worksheet //= 'not';
    my @i_l = (__ 'file:', __ 'worksheet:');
    my @i_v = ($self->reader_options->file, $worksheet);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@i_l,                                                              \@i_v;

    #-- Output

    my $output_l = __ 'Output:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                 $output_l;
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($self->recipe->destination->table, $database);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@o_l,                                                              \@o_v;

    return;
}

sub transfer_db2db {
    my $self = shift;

    my $src_table  = $self->recipe->source->table;
    my $dst_table  = $self->recipe->destination->table;
    my $src_engine = $self->reader->target->engine;
    my $dst_engine = $self->writer->target->engine;
    my $src_db     = $src_engine->database;
    my $dst_db     = $dst_engine->database;

    $self->job_info_db2db($src_db, $dst_db);

    hurl run => __x( "The source table '{table}' does not exists!",
        table => $src_table )
        unless $src_engine->table_exists($src_table);

    hurl run => __x( "The destination table '{table}' does not exists!",
        table => $dst_table )
        unless $dst_engine->table_exists($dst_table);

    # XXX Have to also check the host
    hurl run =>
        __( 'The source and the destination tables must be different!' )
        if ( $src_table eq $dst_table ) and ( $src_db eq $dst_db );

    my $table_info = $dst_engine->get_info($dst_table);
    hurl run => __( 'No columns type info retrieved from database!' )
        if keys %{$table_info} == 0;

    # Log field name
    my $logfld = $self->recipe->tables->get_table($dst_table)->logfield;
    unless ($logfld) {
        my @cols = $self->sort_hash_by_pos($table_info);
        $logfld = shift @cols;              # that the first column is
    }

    my $iter = $self->_contents_iter;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        $row    = $self->do_transformations($row, $table_info, $logfld);
        $self->writer->insert($dst_table, $row);

        #last;                   # DEBUG
    }

    return;
}

sub job_info_db2db {
    my ($self, $src_db, $dst_db) = @_;

    #-- Input

    my $input_l  = __ 'Input:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                  $input_l;
    my @i_l = (__ 'table:', __ 'database:');
    my @i_v = ($self->recipe->source->table, $src_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@i_l,                                                              \@i_v;

    #-- Output

    my $output_l = __ 'Output:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                 $output_l;
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($self->recipe->destination->table, $dst_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@o_l,                                                              \@o_v;

    return;
}

sub job_summary {
    my $self = shift;

    #-- Summary

    my $summ_l = __ 'Summary:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                   $summ_l;
    my @o_l = (__ 'records inserted:', __ 'records skipped:');
    my @o_v = ( $self->writer->records_inserted,
                $self->writer->records_skipped );
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@o_l,                                                              \@o_v;
    print form
    " -----------------------------";
    return;
}

sub do_transformations {
    my ($self, $columns, $info, $logfld) = @_;

    #--  Logging settings

    my $logidx = exists $columns->{$logfld} ? $columns->{$logfld} : '?';
    my $logstr = qq{[$logfld=$logidx]};

    #--  Custom per field transformations from the recipe

    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $field = $step->field;
        hurl field_info => __x(
            "Field info for '{field}' not found!  Header map config. <--> DB schema inconsistency",
            field => $field,
        ) unless exists $info->{$field} and ref $info->{$field};
        my $p = $info->{$field};
        $p->{logstr} = $logstr;
        $p->{value}  = $columns->{$field};
        foreach my $meth ( @{ $step->method } ) {
            $p->{value} = $self->plugin->do_transform( $meth, $p );
        }
        $columns->{$field} = $p->{value};
    }

    #--  Transformations per record (row)

    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $type = $step->type;
        if ( $type and $self->trafo->exists_in_type($type) ) {
            $columns = $self->trafo->get_type($type)->($self, $step, $columns);
        }
        else {
            hurl trafo_type =>
                __x( "Trafo type {type} not implemented", type => $type );
        }
    }

    #--  Transformations per field type

    while ( my ( $field, $value ) = each( %{$columns} ) ) {
        hurl field_info => __x(
            "Field info for '{field}' not found!  Header map config. <--> DB schema inconsistency",
            field => $field
        ) unless exists $info->{$field} and ref $info->{$field};
        my $p = $info->{$field};
        $p->{logstr} = $logstr;
        $p->{value}  = $value;    # add the value to p
        $p->{value}  = $self->plugin->do_transform( $p->{type}, $p );
        $columns->{$field} = $p->{value};
    }

    return $columns;
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
